import type { PageServerLoad } from './$types'
import Auth from '$lib/server/auth'
import Access from '$lib/server/access'

export const load: PageServerLoad = async (event) => {
	await Access.isAdmin.require(event)
	Auth.protect.requireRecentAuth(event, 'redirect', 'default')

	return
}
