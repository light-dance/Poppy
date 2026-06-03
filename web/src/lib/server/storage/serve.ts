import { error, redirect } from '@sveltejs/kit'
import type { RequestHandler } from '@sveltejs/kit'
import { s3, redis } from './setup'

/** Presigned URL expiry time: 7 days */
const PRESIGN_EXPIRY = 7 * 24 * 60 * 60 // 604800 seconds

/** Cache TTL: 6 days (1 day buffer before URL expires) */
const CACHE_TTL = 6 * 24 * 60 * 60 // 518400 seconds

/**
 * Serve public content with cached presigned URLs.
 *
 * Returns a SvelteKit RequestHandler that:
 * 1. Checks Redis cache for existing presigned URL
 * 2. Verifies file exists in S3
 * 3. Generates and caches presigned URL
 * 4. Redirects to the presigned URL
 *
 * @example
 * ```typescript
 * // In +server.ts
 * import { servePublic } from '$lib/server/storage'
 * export const GET = servePublic()
 * ```
 */
export function servePublic(): RequestHandler {
	return async ({ params }) => {
		const fileKey = params.path

		if (!fileKey) {
			throw error(404, 'Not found')
		}

		const cacheKey = `content:${fileKey}`

		// Check cache for existing presigned URL
		const cachedUrl = await redis.get(cacheKey)
		if (cachedUrl) {
			throw redirect(302, cachedUrl)
		}

		// Verify file exists in S3
		try {
			const stat = await s3.stat(fileKey)
			if (!stat) {
				throw error(404, 'Not found')
			}
		} catch {
			throw error(404, 'Not found')
		}

		// Generate presigned GET URL
		const presignedUrl = s3.presign(fileKey, {
			method: 'GET',
			expiresIn: PRESIGN_EXPIRY
		})

		// Cache the presigned URL
		await redis.send('SET', [cacheKey, presignedUrl, 'EX', String(CACHE_TTL)])

		// Redirect to the presigned URL
		throw redirect(302, presignedUrl)
	}
}

interface ServeProtectedOptions {
	/**
	 * Authorization callback. Throw an error to deny access.
	 *
	 * @param context - Contains fileKey, path, and locals
	 * @throws {Error} Throw SvelteKit error() to deny access
	 *
	 * @example
	 * ```typescript
	 * authorize: ({ locals, fileKey }) => {
	 *   if (!locals.user) throw error(401, 'Unauthorized')
	 *   if (!fileKey.startsWith(`users/${locals.user.id}/`)) {
	 *     throw error(403, 'Forbidden')
	 *   }
	 * }
	 * ```
	 */
	authorize: (context: {
		fileKey: string
		path: string
		locals: App.Locals
	}) => Promise<void> | void
}

/** Base path for content routes */
const CONTENT_BASE = '/content/'

/**
 * Serve protected content with authorization check.
 *
 * Returns a SvelteKit RequestHandler that:
 * 1. Extracts the full S3 key from the URL path (everything after /content/)
 * 2. Runs the authorize callback (throws if unauthorized)
 * 3. Verifies file exists in S3
 * 4. Generates presigned URL (not cached)
 * 5. Redirects to the presigned URL
 *
 * @example
 * ```typescript
 * // In +server.ts for route /content/profile-pic/[...resource]
 * import { serveProtected } from '$lib/server/storage'
 *
 * export const GET = serveProtected({
 *   authorize: ({ locals, fileKey }) => {
 *     // fileKey = "profile-pic/user-123/file.jpg" (full S3 key)
 *     if (!locals.user) throw error(401, 'Unauthorized')
 *   }
 * })
 * ```
 */
export function serveProtected(options: ServeProtectedOptions): RequestHandler {
	return async ({ params, locals, url }) => {
		// Extract full path after /content/ to get the S3 key
		const fileKey = url.pathname.startsWith(CONTENT_BASE)
			? url.pathname.slice(CONTENT_BASE.length)
			: params.path

		if (!fileKey) {
			throw error(404, 'Not found')
		}

		// Run authorization check
		await options.authorize({ fileKey, path: params.path ?? '', locals })

		// Verify file exists in S3
		try {
			const stat = await s3.stat(fileKey)
			if (!stat) {
				throw error(404, 'Not found')
			}
		} catch {
			throw error(404, 'Not found')
		}

		// Generate presigned GET URL (no caching for protected content)
		const presignedUrl = s3.presign(fileKey, {
			method: 'GET',
			expiresIn: PRESIGN_EXPIRY
		})

		// Redirect to the presigned URL
		throw redirect(302, presignedUrl)
	}
}
