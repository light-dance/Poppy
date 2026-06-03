import { redirect } from '@sveltejs/kit'
import Auth from '$lib/server/auth'
import type { PageServerLoad } from './$types'

export const load: PageServerLoad = async (event) => {
	if (!event.locals.user || !event.locals.session) {
		throw redirect(303, Auth.routes.login)
	}

	const user = event.locals.user
	const userLock = event.locals.userLocked

	// Unlocked users should not remain on lock screen
	if (userLock.length === 0) {
		throw redirect(303, Auth.redirects.afterLogin)
	}

	return {
		userLock,
		identifier: user.identifier
	}
}
