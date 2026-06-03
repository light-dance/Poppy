import { error, type Handle } from '@sveltejs/kit'
import { resolveClientAddress } from '../utils/resolve-client-address'
import { limits } from './limits'

export const handleGlobalRatelimit: Handle = async ({ event, resolve }) => {
	// Early return to skip on /health route
	if (event.url.pathname === '/health') {
		return resolve(event)
	}

	const ip = resolveClientAddress(event)

	const rate = await limits.general.limit(ip)

	// If rate limit exceeded, send back error
	if (!rate.success) {
		error(429, `Rate limit exceeded. Try again at ${rate.reset}`)
	}

	const result = await resolve(event)
	// Add rate limit headers
	result.headers.set('X-RateLimit-Limit', rate.limit.toString())
	result.headers.set('X-RateLimit-Remaining', rate.remaining.toString())
	result.headers.set('X-RateLimit-Reset', rate.reset.toString())

	return result
}
