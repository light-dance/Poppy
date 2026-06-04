import { redirect } from '@sveltejs/kit'

import { resolveDownload, validateVersion } from '$lib/server/releases'

export async function GET({ params }) {
	const file = await resolveDownload({
		version: validateVersion(params.version),
		format: 'dmg'
	})

	throw redirect(302, `/${file}`)
}
