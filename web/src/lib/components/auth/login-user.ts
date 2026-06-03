/**
 * Handles post-login actions and redirect.
 * Clears lastSeenAt to ensure welcome animation plays on next protected page load.
 */
export function handleLoginSuccess(redirectUrl: string) {
	localStorage.removeItem('lastSeenAt')
	window.location.href = redirectUrl
}
