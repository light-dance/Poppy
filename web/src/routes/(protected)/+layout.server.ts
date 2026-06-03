import type { ServerLoad } from '@sveltejs/kit'

export const load: ServerLoad = async (event) => {
	event.cookies.delete('homepageIntent', { path: '/' })

	// Forces the hooks to run
	return
}
