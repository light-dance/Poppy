import { type Handle } from '@sveltejs/kit'
import { sequence } from '@sveltejs/kit/hooks'

import { scheduledTasks } from '$lib/server/scheduled'
import { ratelimit } from '$lib/server/ratelimit'

scheduledTasks() // start running scheduled tasks

export const handle: Handle = sequence(
	ratelimit.handleGlobalRatelimit // enforce global rate limits
)
