import type { ServerLoad } from '@sveltejs/kit'
import { redirect } from '@sveltejs/kit'
import Auth from '$lib/server/auth'
import AuthCore from '$lib/server/auth/core'

export const load: ServerLoad = async (event) => {
	Auth.protect.requireAuthenticatedUser(event, 'redirect')

	const recentAuth = Auth.protect.checkRecentAuth(event)

	if (recentAuth) {
		const redirectUrl = AuthCore.redirectUrlCookie.consume(event)
		const redirectPathname = redirectUrl?.split('?', 1)[0] // URL without query params

		// Prevent redirect to reauth (infinite loop)
		if (redirectPathname === Auth.routes.reauth) {
			throw redirect(303, Auth.redirects.afterLogin)
		}

		throw redirect(303, redirectUrl ?? Auth.redirects.afterLogin)
	}

	return
}
