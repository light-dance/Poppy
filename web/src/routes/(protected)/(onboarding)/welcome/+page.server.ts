import { redirect } from '@sveltejs/kit'
import type { PageServerLoad } from './$types'
import Auth from '$lib/server/auth'

export const load: PageServerLoad = async ({ locals }) => {
	const { user } = locals

	if (!user) {
		throw redirect(302, Auth.routes.login)
	}

	// If account was created more than recentAuthWindow ago, redirect to main app
	const accountAge = Date.now() - user.createdAt.getTime()
	if (accountAge > Auth.durations.recentAuthWindow) {
		throw redirect(302, Auth.redirects.afterLogin)
	}

	return {
		afterLoginRedirect: Auth.redirects.afterLogin
	}
}
