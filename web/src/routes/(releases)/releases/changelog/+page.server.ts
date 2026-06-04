import { listReleaseNotes } from '$lib/server/releases'

export async function load() {
	return {
		releases: await listReleaseNotes()
	}
}
