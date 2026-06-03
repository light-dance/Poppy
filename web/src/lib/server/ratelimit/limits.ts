import { Ratelimit } from '@upstash/ratelimit'
import { createRatelimit } from './setup'

export const limits = {
	/**
	 * General rate limit for visiting site.
	 * - Algorithm: Fixed window
	 * - Limit: 90 requests per 60 seconds
	 */
	general: createRatelimit({
		prefix: 'ratelimit:general',
		limiter: Ratelimit.fixedWindow(90, '60 s')
	}),

	/**
	 * Limit for downloading assets.
	 * - Algorithm: Fixed window
	 * - Limit: 10 requests per 60 seconds
	 */
	download: createRatelimit({
		prefix: 'ratelimit:download',
		limiter: Ratelimit.fixedWindow(10, '60 s')
	})
}
