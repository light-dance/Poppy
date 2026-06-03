import { type Handle } from '@sveltejs/kit'
import { sequence } from '@sveltejs/kit/hooks'

import { scheduledTasks } from '$lib/server/scheduled'
import { ratelimit } from '$lib/server/ratelimit'
import Auth from '$lib/server/auth'
import { AccessHooks } from '$lib/server/access'

scheduledTasks() // start running scheduled tasks

export const handle: Handle = sequence(
	ratelimit.handleGlobalRatelimit, // enforce global rate limits
	Auth.hooks.handleAuthentication, // validate session and set user
	AccessHooks.handleAccess, // resolve access flags for user
	Auth.hooks.handleProtected // guard protected routes, redirect if needed
)
