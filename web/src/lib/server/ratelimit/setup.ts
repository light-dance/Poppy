import { RedisClient } from 'bun'
import { REDIS_URL } from '$env/static/private'
import { Ratelimit } from '@upstash/ratelimit'
import { BunRedisAdapter } from './adapter-bun'

const redis = new RedisClient(REDIS_URL) // Init Redis connection
const bunRedis = new BunRedisAdapter(redis) // wrapping in bun adapter

type AnyAlgorithm =
	| ReturnType<typeof Ratelimit.fixedWindow>
	| ReturnType<typeof Ratelimit.slidingWindow>
	| ReturnType<typeof Ratelimit.tokenBucket>
	| ReturnType<typeof Ratelimit.cachedFixedWindow>

/**
 * Create a rate limiter with Bun Redis adapter
 *
 * @example
 * ```ts
 * const limiter = createRatelimiter({
 *   prefix: 'api:auth',
 *   limiter: Ratelimit.fixedWindow(10, '10s')
 * })
 * ```
 */
export function createRatelimit(config: { prefix: string; limiter: AnyAlgorithm }) {
	return new Ratelimit({
		redis: bunRedis,
		analytics: false,
		limiter: config.limiter,
		prefix: config.prefix
	})
}
