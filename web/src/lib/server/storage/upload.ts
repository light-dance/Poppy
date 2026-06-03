import * as v from 'valibot'
import { s3, redis } from './setup'

// ============================================================================
// File Size Parsing
// ============================================================================

type FileSizeUnit = 'B' | 'KB' | 'MB' | 'GB'
type FileSize = `${number}${FileSizeUnit}`

const SIZE_MULTIPLIERS: Record<FileSizeUnit, number> = {
	B: 1,
	KB: 1024,
	MB: 1024 ** 2,
	GB: 1024 ** 3
}

function parseFileSize(size: FileSize): number {
	const match = size.match(/^(\d+(?:\.\d+)?)(B|KB|MB|GB)$/i)
	if (!match) {
		throw new Error(`Invalid file size format: ${size}. Expected format like "2MB", "500KB", etc.`)
	}
	const [, value, unit] = match
	return Math.floor(parseFloat(value) * SIZE_MULTIPLIERS[unit.toUpperCase() as FileSizeUnit])
}

// ============================================================================
// File Type Handling (MIME Types)
// ============================================================================

/** Shortcut mappings for common file type groups */
const FILE_TYPE_MAP: Record<string, string[]> = {
	image: ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml'],
	video: ['video/mp4', 'video/webm', 'video/ogg', 'video/quicktime'],
	audio: ['audio/mpeg', 'audio/ogg', 'audio/wav', 'audio/webm'],
	pdf: ['application/pdf'],
	text: ['text/plain', 'text/html', 'text/css', 'text/javascript'],
	blob: ['application/octet-stream']
}

type FileType = keyof typeof FILE_TYPE_MAP | string | string[]

/**
 * Resolve file type config to an array of allowed MIME types
 * - 'image' -> ['image/jpeg', 'image/png', ...]
 * - 'image/jpeg' -> ['image/jpeg']
 * - ['image/jpeg', 'image/png'] -> ['image/jpeg', 'image/png']
 */
function resolveAllowedTypes(fileType: FileType): string[] {
	if (Array.isArray(fileType)) {
		return fileType
	}
	if (fileType in FILE_TYPE_MAP) {
		return FILE_TYPE_MAP[fileType as keyof typeof FILE_TYPE_MAP]
	}
	return [fileType]
}

// ============================================================================
// Types
// ============================================================================

interface BaseConfig {
	/**
	 * Maximum allowed file size.
	 *
	 * Can be specified as:
	 * - A number (bytes): `5242880`
	 * - A string with unit: `'5MB'`, `'500KB'`, `'1GB'`
	 *
	 * Files exceeding this size will be deleted and an error thrown in `complete()`.
	 */
	maxSize: FileSize | number

	/**
	 * Allowed file type(s) for upload.
	 *
	 * Can be specified as:
	 * - A shortcut: `'image'`, `'video'`, `'audio'`, `'pdf'`, `'text'`, `'blob'`
	 * - A specific MIME type: `'image/jpeg'`, `'application/pdf'`
	 * - An array of MIME types: `['image/jpeg', 'image/png']`
	 *
	 * When calling `start()`, the client must specify which content type they're
	 * uploading, and it will be validated against this list.
	 */
	fileType: FileType

	/**
	 * How long the presigned upload URL is valid, in seconds.
	 *
	 * @default 300 (5 minutes)
	 */
	expiresIn?: number
}

interface ConfigWithKey<TKeyInput> extends BaseConfig {
	/**
	 * Function to generate a custom S3 key for the upload.
	 *
	 * Receives typed input that must be provided when calling `start()`.
	 * If not specified, a UUID-based key will be generated automatically.
	 *
	 * @example
	 * ```typescript
	 * customKey: (input: { userId: string }) =>
	 *   `profile-pic/${input.userId}/${Date.now()}.jpg`
	 * ```
	 */
	customKey: (input: TKeyInput) => string
}

interface ConfigWithMetadata<TMetadata extends v.GenericSchema> extends BaseConfig {
	/**
	 * Valibot schema for typed metadata to associate with the upload.
	 *
	 * Metadata is passed in `start()` and returned in `complete()`,
	 * useful for passing context through the upload flow.
	 *
	 * @example
	 * ```typescript
	 * metadata: v.object({
	 *   uploadedBy: v.string(),
	 *   description: v.optional(v.string())
	 * })
	 * ```
	 */
	metadata: TMetadata
}

interface ConfigWithKeyAndMetadata<
	TKeyInput,
	TMetadata extends v.GenericSchema
> extends BaseConfig {
	/**
	 * Function to generate a custom S3 key for the upload.
	 *
	 * Receives typed input that must be provided when calling `start()`.
	 * If not specified, a UUID-based key will be generated automatically.
	 *
	 * @example
	 * ```typescript
	 * customKey: (input: { userId: string }) =>
	 *   `profile-pic/${input.userId}/${Date.now()}.jpg`
	 * ```
	 */
	customKey: (input: TKeyInput) => string

	/**
	 * Valibot schema for typed metadata to associate with the upload.
	 *
	 * Metadata is passed in `start()` and returned in `complete()`,
	 * useful for passing context through the upload flow.
	 *
	 * @example
	 * ```typescript
	 * metadata: v.object({
	 *   uploadedBy: v.string(),
	 *   description: v.optional(v.string())
	 * })
	 * ```
	 */
	metadata: TMetadata
}

/** Forces TypeScript to expand type definitions on hover */
type Expand<T> = T extends infer O ? { [K in keyof O]: O[K] } : never

export type StartResult = Expand<{
	/** Presigned URL for uploading directly to S3 */
	uploadUrl: string
	/** The S3 key where the file will be stored */
	fileKey: string
	/** Token to pass to `complete()` after upload finishes */
	uploadToken: string
	/** Headers to include in the upload fetch request */
	uploadHeaders: {
		'Content-Type': string
	}
}>

export type CompleteResult<TMetadata> = Expand<{
	/** The S3 key where the file was stored */
	fileKey: string
	/** Metadata passed in `start()`, typed per your Valibot schema */
	metadata: TMetadata
}>

// Base options that always include contentType
interface StartOptionsBase {
	contentType: string
}

// Upload route interface with conditional start() signature
interface UploadRoute<TKeyInput, TMetadata> {
	start: TKeyInput extends void
		? TMetadata extends void
			? (options: StartOptionsBase) => Promise<StartResult>
			: (options: StartOptionsBase & { metadata: TMetadata }) => Promise<StartResult>
		: TMetadata extends void
			? (options: StartOptionsBase & { key: TKeyInput }) => Promise<StartResult>
			: (
					options: StartOptionsBase & { key: TKeyInput; metadata: TMetadata }
				) => Promise<StartResult>

	complete: (uploadToken: string) => Promise<CompleteResult<TMetadata>>
}

// ============================================================================
// Function Overloads
// ============================================================================

/**
 * Define an upload route for secure direct-to-S3 uploads.
 *
 * **Config options:**
 * - `maxSize` (required) - Max file size: `'5MB'`, `'500KB'`, or bytes
 * - `fileType` (required) - Allowed types: `'image'`, `'image/jpeg'`, or `['image/jpeg', 'image/png']`
 * - `expiresIn` (optional) - Presigned URL validity in seconds (default: 300)
 * - `customKey` (optional) - Function to generate S3 key from typed input
 * - `metadata` (optional) - Valibot schema for typed metadata passed through upload flow
 *
 * **Returns an upload route with:**
 * - `start({ contentType, key?, metadata? })` - Returns `{ uploadUrl, fileKey, uploadToken }`
 * - `complete(uploadToken)` - Validates upload, returns `{ fileKey, metadata }`
 *
 * @example
 * ```typescript
 * const upload = defineUpload({
 *   customKey: (input: { userId: string }) => `pics/${input.userId}/${Date.now()}.jpg`,
 *   metadata: v.object({ source: v.string() }),
 *   maxSize: '5MB',
 *   fileType: 'image/jpeg'
 * })
 * ```
 */
export function defineUpload(config: BaseConfig): UploadRoute<void, void>

export function defineUpload<TKeyInput>(
	config: ConfigWithKey<TKeyInput>
): UploadRoute<TKeyInput, void>

export function defineUpload<TMetadata extends v.GenericSchema>(
	config: ConfigWithMetadata<TMetadata>
): UploadRoute<void, v.InferOutput<TMetadata>>

export function defineUpload<TKeyInput, TMetadata extends v.GenericSchema>(
	config: ConfigWithKeyAndMetadata<TKeyInput, TMetadata>
): UploadRoute<TKeyInput, v.InferOutput<TMetadata>>

// ============================================================================
// Implementation
// ============================================================================

export function defineUpload<TKeyInput = void, TMetadata extends v.GenericSchema | void = void>(
	config: BaseConfig & {
		customKey?: (input: TKeyInput) => string
		metadata?: TMetadata
	}
): UploadRoute<TKeyInput, TMetadata extends v.GenericSchema ? v.InferOutput<TMetadata> : void> {
	const { customKey, metadata: metadataSchema, fileType, expiresIn = 300 } = config

	const maxSizeBytes =
		typeof config.maxSize === 'string' ? parseFileSize(config.maxSize) : config.maxSize

	const allowedTypes = resolveAllowedTypes(fileType)

	type InferredMetadata = TMetadata extends v.GenericSchema ? v.InferOutput<TMetadata> : void

	return {
		async start(options?: {
			key?: TKeyInput
			metadata?: InferredMetadata
			contentType?: string
		}): Promise<StartResult> {
			const keyInput = options?.key
			const metadata = options?.metadata
			const contentType = options?.contentType ?? allowedTypes[0]

			// Validate content type is allowed
			if (!allowedTypes.includes(contentType)) {
				throw new Error(
					`Content type "${contentType}" is not allowed. Allowed types: ${allowedTypes.join(', ')}`
				)
			}

			// Validate metadata if schema provided
			if (metadataSchema && metadata !== undefined) {
				const schema = metadataSchema as v.GenericSchema
				v.parse(schema, metadata)
			}

			// Single UUID used for upload token and default file key
			const uploadToken = crypto.randomUUID()

			// Final destination key - from customKey() or default to uploads/{token}
			const fileKey =
				customKey && keyInput !== undefined ? customKey(keyInput) : `uploads/${uploadToken}`

			// Generate presigned PUT URL for the final location
			const uploadUrl = s3.presign(fileKey, {
				method: 'PUT',
				expiresIn,
				type: contentType
			})

			// Calculate when this upload expires (for cleanup job)
			const expiresAt = Date.now() + expiresIn * 1000

			// Store upload data in Redis (no TTL - cleanup job handles expiry)
			const uploadData = JSON.stringify({
				metadata: metadata ?? null,
				fileKey,
				contentType,
				maxSizeBytes,
				expiresAt
			})

			await redis.send('SET', [`upload:${uploadToken}`, uploadData])

			return {
				uploadUrl,
				fileKey,
				uploadToken,
				uploadHeaders: {
					'Content-Type': contentType
				}
			}
		},

		async complete(uploadToken: string): Promise<CompleteResult<InferredMetadata>> {
			const rawUploadData = await redis.get(`upload:${uploadToken}`)

			if (!rawUploadData) {
				throw new Error('Upload token expired or invalid')
			}

			const uploadData = JSON.parse(rawUploadData) as {
				metadata: InferredMetadata | null
				fileKey: string
				contentType: string
				maxSizeBytes: number
				expiresAt: number
			}

			const { metadata, fileKey, contentType, maxSizeBytes: maxSize } = uploadData

			// Verify file exists in S3 and get its info
			const stat = await s3.stat(fileKey)
			if (!stat) {
				throw new Error('File not found in storage')
			}

			// Validate file size
			if (stat.size > maxSize) {
				await s3.delete(fileKey)
				await redis.send('DEL', [`upload:${uploadToken}`])
				throw new Error(
					`File size ${stat.size} bytes exceeds maximum allowed size of ${maxSize} bytes`
				)
			}

			// Validate content type matches what was declared
			if (stat.type && stat.type !== contentType) {
				await s3.delete(fileKey)
				await redis.send('DEL', [`upload:${uploadToken}`])
				throw new Error(
					`File content type "${stat.type}" does not match declared type "${contentType}"`
				)
			}

			// Delete token from Redis - upload is now complete
			await redis.send('DEL', [`upload:${uploadToken}`])

			return {
				fileKey,
				metadata: metadata as InferredMetadata
			}
		}
	} as UploadRoute<TKeyInput, InferredMetadata>
}

/** Shape of upload data stored in Redis */
interface PendingUpload {
	metadata: unknown
	fileKey: string
	contentType: string
	maxSizeBytes: number
	expiresAt: number
}

/**
 * Clean up expired pending uploads.
 *
 * Scans all `upload:*` keys in Redis, and for any where `expiresAt + 30s < now`:
 * - Deletes the S3 file
 * - Deletes the Redis key
 *
 * This handles orphaned uploads where the client never called `complete()`.
 */
export async function cleanupExpiredUploads(): Promise<{ deleted: number; errors: number }> {
	/** Buffer time before cleaning up expired uploads (in ms) */
	const CLEANUP_BUFFER_MS = 30 * 1000 // 30 seconds

	let deleted = 0
	let errors = 0

	// Scan for all upload:* keys
	const keys = (await redis.send('KEYS', ['upload:*'])) as string[]

	if (!keys || keys.length === 0) {
		return { deleted, errors }
	}

	const now = Date.now()

	for (const key of keys) {
		try {
			const rawData = await redis.get(key)
			if (!rawData) continue

			const data = JSON.parse(rawData) as PendingUpload

			// Check if expired (with 30s buffer to avoid race conditions)
			if (data.expiresAt + CLEANUP_BUFFER_MS < now) {
				// Delete the S3 file
				await s3.delete(data.fileKey)

				// Delete the Redis key
				await redis.send('DEL', [key])

				deleted++
			}
		} catch (err) {
			console.error(`Failed to cleanup upload ${key}:`, err)
			errors++
		}
	}

	return { deleted, errors }
}
