import { redirect } from '@sveltejs/kit'

export const GET = (event) => {
	event.cookies.set('homepageIntent', 'true', {
		httpOnly: true,
		sameSite: 'lax',
		maxAge: 60 * 90, // 90 mins
		path: '/'
	})

	throw redirect(303, '/')
}
