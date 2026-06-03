import { Ratelimit } from '@upstash/ratelimit'
import { createRatelimit } from './setup'

export const limits = {
	/**
	 * General rate limit for free tier users.
	 * - Algorithm: Fixed window
	 * - Limit: 90 requests per 60 seconds
	 */
	free: createRatelimit({
		prefix: 'ratelimit:free',
		limiter: Ratelimit.fixedWindow(90, '60 s')
	}),

	/**
	 * General rate limit for paid tier users.
	 * - Algorithm: Fixed window
	 * - Limit: 300 requests per 60 seconds
	 */
	paid: createRatelimit({
		prefix: 'ratelimit:paid',
		limiter: Ratelimit.fixedWindow(300, '60 s')
	}),

	auth: {
		/**
		 * Standard auth operations rate limit.
		 * For general operations like fetching user data, listing sessions.
		 * - Algorithm: Fixed window
		 * - Limit: 60 requests per 60 seconds
		 */
		standard: createRatelimit({
			prefix: 'ratelimit:auth-standard',
			limiter: Ratelimit.fixedWindow(60, '60 s')
		}),

		expensive: {
			/**
			 * Short-term limit for expensive auth operations.
			 * Prevents rapid-fire attempts (e.g., spamming login codes).
			 * - Algorithm: Fixed window
			 * - Limit: 5 request per 60 seconds
			 */
			short: createRatelimit({
				prefix: 'ratelimit:auth-expensive-short',
				limiter: Ratelimit.fixedWindow(5, '60 s')
			}),

			/**
			 * Long-term limit for expensive auth operations.
			 * Prevents sustained abuse over longer periods.
			 * - Algorithm: Token bucket
			 * - Bucket size: 20 tokens max
			 * - Refill: 10 tokens per 6 hours
			 */
			long: createRatelimit({
				prefix: 'ratelimit:auth-expensive-long',
				limiter: Ratelimit.tokenBucket(10, '6 h', 20)
			})
		}
	}
}
