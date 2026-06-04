import { validateVersion, getReleaseNotes, isLatestRelease } from '$lib/server/releases'

export async function load({ params }) {
	const version = validateVersion(params.version)
	const [release, isLatest] = await Promise.all([
		getReleaseNotes(version),
		isLatestRelease(version)
	])

	return {
		release,
		isLatest
	}
}
