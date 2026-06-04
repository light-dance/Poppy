import { getDownloadURL, validateFormat, validateVersion } from '$lib/server/releases'

export async function GET({ params }) {
	return await getDownloadURL({
		version: validateVersion(params.version),
		format: validateFormat(params.format)
	})
}
