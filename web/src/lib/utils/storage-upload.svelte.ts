interface CreateUploadOptions<TResult> {
	start: () => Promise<{
		uploadUrl: string
		uploadToken: string
		uploadHeaders: Record<string, string>
	}>
	complete: (uploadToken: string) => Promise<TResult>
}

interface UploadState<TResult> {
	isUploading: boolean
	error: string | null
	result: TResult | null
	send: (file: Blob) => Promise<void>
}

export function createUpload<TResult>(options: CreateUploadOptions<TResult>): UploadState<TResult> {
	let isUploading = $state(false)
	let error = $state<string | null>(null)
	let result = $state<TResult | null>(null)

	async function send(file: Blob): Promise<void> {
		isUploading = true
		error = null
		result = null

		try {
			// 1. Call start to get presigned URL
			const { uploadUrl, uploadToken, uploadHeaders } = await options.start()

			// 2. Upload directly to S3
			const response = await fetch(uploadUrl, {
				method: 'PUT',
				body: file,
				headers: uploadHeaders
			})

			if (!response.ok) {
				throw new Error(`Upload failed: ${response.status}`)
			}

			// 3. Call complete to finalize
			result = await options.complete(uploadToken)
		} catch (e) {
			error = e instanceof Error ? e.message : 'Upload failed'
			throw e
		} finally {
			isUploading = false
		}
	}

	return {
		get isUploading() {
			return isUploading
		},
		get error() {
			return error
		},
		get result() {
			return result
		},
		send
	}
}
