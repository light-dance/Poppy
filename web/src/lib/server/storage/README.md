# storage

S3 file uploads and serving using Bun's S3Client and Redis. (Tested with Railway's buckets)

## Files

- `setup.ts` - S3 and Redis client initialization
- `upload.ts` - `defineUpload()` factory + `cleanupExpiredUploads()`
- `serve.ts` - `servePublic()` and `serveProtected()` request handlers
- `index.ts` - Re-exports

## Upload Flow

You should setup a remote function for each upload route.

```typescript
// lib/remotes/storage/profile-pic.remote.ts
import { defineUpload } from '$lib/server/storage'

const upload = defineUpload({
	maxSize: '5MB',
	fileType: 'image/jpeg',
	expiresIn: 300,
	customKey: (input: { userId: string }) => `pics/${input.userId}/${Date.now()}.jpg`,
	metadata: v.object({ source: v.string() })
})

// 1. Server: get presigned URL
const { uploadUrl, uploadToken, uploadHeaders } = await upload.start({
	contentType: 'image/jpeg',
	key: { userId },
	metadata: { source: 'profile' }
})

// 2. Client: upload directly to S3
// await fetch(uploadUrl, { method: 'PUT', headers: uploadHeaders, body: file })

// 3. Server: validate and finalize
const { fileKey, metadata } = await upload.complete(uploadToken)
```

## Client Utility

`$lib/utils/storage-upload.svelte.ts` provides a upload helper:

```typescript
const upload = createUpload({
	start: () => startMyUpload(),
	complete: (token) => completeMyUpload({ uploadToken: token })
})

// upload.isUploading, upload.error, upload.result
await upload.send(file)
```

### defineUpload options

| Option      | Required | Description                                                 |
| ----------- | -------- | ----------------------------------------------------------- |
| `maxSize`   | yes      | `'5MB'`, `'500KB'`, or bytes                                |
| `fileType`  | yes      | `'image'`, `'image/jpeg'`, or `['image/jpeg', 'image/png']` |
| `expiresIn` | no       | Presigned URL validity in seconds (default: 300)            |
| `customKey` | no       | `(input) => string` for custom S3 keys                      |
| `metadata`  | no       | Valibot schema for typed data passed through flow           |

### File type shortcuts

`'image'`, `'video'`, `'audio'`, `'pdf'`, `'text'`, `'blob'`

## Serving

```typescript
// Public: cached presigned URLs
export const GET = servePublic()

// Protected: authorization check, no caching
export const GET = serveProtected({
	authorize: ({ locals, fileKey }) => {
		if (!locals.user) throw error(401)
		if (!fileKey.startsWith(`users/${locals.user.id}/`)) throw error(403)
	}
})
```

### Routes

Content routes live at `src/routes/content/` using route groups for organization:

- `(public)/` - Publicly accessible files via `servePublic()`
- `(protected)/` - Auth-required files via `serveProtected()`

## Cleanup

`cleanupExpiredUploads()` deletes orphaned S3 files where client never called `complete()`. Run via scheduled task.
