import type { ServerLoad } from '@sveltejs/kit'
import { redirect } from '@sveltejs/kit'
import Auth from '$lib/server/auth'

export const load: ServerLoad = async (event) => {
	await Auth.protect.requireSession(event)

	if (event.locals.user) {
		throw redirect(303, Auth.redirects.afterLogin)
	}

	return {
		title: 'Welcome to Spring',
		text: 'Log in or sign up to get started'
	}
}
