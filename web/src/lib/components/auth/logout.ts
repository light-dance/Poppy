import { goto } from '$app/navigation'
import { logout } from '$remotes/auth/authenticate.remote'

export const handleLogout = async () => {
	const res = await logout()
	localStorage.removeItem('lastSeenAt')
	// eslint-disable-next-line svelte/no-navigation-without-resolve
	goto(res.redirectUrl)
}
