import { error } from '@sveltejs/kit'

import Auth from '$lib/server/auth'
import AuthCore from '$lib/server/auth/core'

import { defineCheck } from '../types'

/**
 * Checks if the current user is in the admin allowlist.
 * Not hook-populated, call via Access.check/require.
 */
export default defineCheck<boolean>({
	resolve: (event) => {
		const user = event.locals.user
		if (!user) return { value: false, allowed: false, message: 'Not authenticated' }

		const normalizedIdentifier = AuthCore.normalizeIdentifierInput(user.identifier)

		const isAdmin = Auth.admins.some(
			(adminIdentifier) =>
				AuthCore.normalizeIdentifierInput(adminIdentifier) === normalizedIdentifier
		)

		if (!isAdmin) {
			return { value: false, allowed: false, message: 'Your account is not admin' }
		}

		return { value: true, allowed: true }
	},
	onDeny: (_, message) => {
		throw error(403, message)
	}
})
