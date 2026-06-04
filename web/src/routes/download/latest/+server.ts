import { getDownloadURL } from '$lib/server/releases'

export async function GET() {
	console.log('test')
	return await getDownloadURL({
		version: 'latest',
		format: 'dmg'
	})
}
