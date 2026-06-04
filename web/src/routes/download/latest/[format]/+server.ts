import { getDownloadURL, validateFormat } from '$lib/server/releases'

export async function GET({ params }) {
	return await getDownloadURL({
		version: 'latest',
		format: validateFormat(params.format)
	})
}
