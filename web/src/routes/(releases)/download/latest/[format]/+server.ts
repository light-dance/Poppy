import { redirect } from '@sveltejs/kit'

import { resolveDownload, validateFormat } from '$lib/server/releases'

export async function GET({ params }) {
	const file = await resolveDownload({
		version: 'latest',
		format: validateFormat(params.format)
	})

	throw redirect(302, `/content/${file}`)
}
