import { redirect } from '@sveltejs/kit'

import { resolveDownload } from '$lib/server/releases'

export async function GET() {
	const file = await resolveDownload({
		version: 'latest',
		format: 'dmg'
	})

	throw redirect(302, `/${file}`)
}
