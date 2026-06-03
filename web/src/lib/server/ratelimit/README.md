# ratelimit

Rate limiting using Upstash Ratelimit with Bun Redis.

## Files

- `adapter-bun.ts` - Adapts Bun's RedisClient to Upstash's Redis interface
- `setup.ts` - Redis connection + `createRatelimit()` factory
- `limits.ts` - All rate limit definitions (free, paid, auth)
- `global-hook.ts` - SvelteKit handle for global request rate limiting
- `index.ts` - Re-exports as unified `ratelimit` object

## Usage

```typescript
import { ratelimit } from '$lib/server/ratelimit'

// In hooks.server.ts
sequence(ratelimit.handleGlobalRatelimit, ...)

// Direct usage
const result = await ratelimit.free.limit(ip)
const result = await ratelimit.auth.sensitive.short.limit(userId)
```

## Adding limits

Add new rates in `limits.ts`

```typescript
import { Ratelimit } from '@upstash/ratelimit'
import { createRatelimit } from './setup'

export const limits = {
	myLimit: createRatelimit({
		prefix: 'ratelimit:my-limit', // unique Redis key prefix
		limiter: Ratelimit.fixedWindow(10, '60 s')
	})
}
```

### Algorithms

- `Ratelimit.fixedWindow(tokens, window)` - Simple counter, resets each window
- `Ratelimit.slidingWindow(tokens, window)` - Smoother, weighted across windows
- `Ratelimit.tokenBucket(refillRate, interval, maxTokens)` - Allows bursts up to max

### Window formats

`'500 ms'`, `'30 s'`, `'5 m'`, `'1 h'`, `'1 d'`
