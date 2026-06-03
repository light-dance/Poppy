import { redirect, type ServerLoad } from '@sveltejs/kit'
import Auth from '$lib/server/auth'

export const load: ServerLoad = async (event) => {
	const homepageIntentCookie = event.cookies.get('homepageIntent')
	const homepageIntentUrl = event.url.searchParams.has('homepage')
	const authedUser = !!event.locals.user

	// Redirect a logged in user
	// Unless they've asked for the homepage
	if (authedUser && !homepageIntentCookie && !homepageIntentUrl) {
		throw redirect(303, Auth.redirects.afterLogin)
	}

	// Set cookie for subsequent requests
	if (homepageIntentUrl) {
		event.cookies.set('homepageIntent', 'true', {
			httpOnly: true,
			sameSite: 'lax',
			maxAge: 60 * 90, // 90 mins
			path: '/'
		})
	}

	return {
		loggedIn: authedUser
	}
}
