import { redirect } from '@sveltejs/kit'

import { resolveDownload, validateFormat, validateVersion } from '$lib/server/releases'

export async function GET({ params }) {
	const file = await resolveDownload({
		version: validateVersion(params.version),
		format: validateFormat(params.format)
	})

	throw redirect(302, `/${file}`)
}
