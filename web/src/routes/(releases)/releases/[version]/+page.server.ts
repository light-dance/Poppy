import { validateVersion, getReleaseNotes } from '$lib/server/releases'

export async function load({ params }) {
	const version = validateVersion(params.version)

	return {
		release: await getReleaseNotes(version)
	}
}
