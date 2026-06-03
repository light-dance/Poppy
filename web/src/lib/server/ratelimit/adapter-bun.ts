/* eslint-disable @typescript-eslint/no-explicit-any */
/**
 * Note: This file uses `any` types intentionally because it must implement
 * a compatible interface with @upstash/ratelimit's Redis client expectations,
 * which uses dynamic types for Redis command arguments and return values.
 */

import type { RedisClient } from 'bun'

/**
 * Bun Redis Adapter for Upstash Ratelimit
 *
 * This adapter makes Bun's native Redis client compatible with the Upstash Ratelimit package.
 * It translates between Upstash's Redis API and Bun's Redis client methods.
 *
 * @example
 * ```typescript
 * import { RedisClient } from "bun";
 * import { Ratelimit } from "@upstash/ratelimit";
 * import { BunRedisAdapter } from "./adapter-bun";
 *
 * const bunRedis = new RedisClient(process.env.REDIS_URL);
 * const adapter = new BunRedisAdapter(bunRedis);
 *
 * const ratelimit = new Ratelimit({
 *   redis: adapter as any,
 *   limiter: Ratelimit.slidingWindow(10, "10 s"),
 *   analytics: false, // Analytics not supported with Bun Redis
 * });
 * ```
 */
export class BunRedisAdapter {
	constructor(private client: RedisClient) {}

	/**
	 * Execute Lua script by hash (EVALSHA)
	 * Upstash signature: evalsha(hash: string, keys: any[], args: any[])
	 * Redis protocol: EVALSHA hash numkeys key1 key2... arg1 arg2...
	 */
	async evalsha(hash: string, keys: any[], args: any[]): Promise<any> {
		const redisArgs = [
			hash,
			String(keys.length), // numkeys
			...keys.map(String), // all keys
			...args.map(String) // all arguments
		]

		return await this.client.send('EVALSHA', redisArgs)
	}

	/**
	 * Execute Lua script directly (EVAL)
	 * Upstash signature: eval(script: string, keys: any[], args: any[])
	 * Redis protocol: EVAL script numkeys key1 key2... arg1 arg2...
	 */
	async eval(script: string, keys: any[], args: any[]): Promise<any> {
		const redisArgs = [script, String(keys.length), ...keys.map(String), ...args.map(String)]

		return await this.client.send('EVAL', redisArgs)
	}

	/**
	 * Set hash field - used by multi-region and token bucket
	 * Handles both signatures:
	 * - hset(key, field, value)
	 * - hset(key, { field: value, ... })
	 */
	async hset(key: string, field: string | Record<string, any>, value?: any): Promise<any> {
		if (typeof field === 'object') {
			// Object form: { field1: value1, field2: value2 }
			const flatArgs = Object.entries(field).flat().map(String)
			return await this.client.send('HSET', [key, ...flatArgs])
		} else {
			// Field/value form: hset(key, field, value)
			return await this.client.send('HSET', [key, String(field), String(value)])
		}
	}

	/**
	 * Get multiple hash fields - used by token bucket algorithm
	 * Redis: HMGET key field1 field2 ...
	 */
	async hmget(key: string, ...fields: string[]): Promise<any> {
		return await this.client.send('HMGET', [key, ...fields])
	}

	/**
	 * Get single hash field value
	 */
	async hget(key: string, field: string): Promise<any> {
		return await this.client.send('HGET', [key, field])
	}

	/**
	 * Get key value
	 */
	async get(key: string): Promise<any> {
		return await this.client.get(key)
	}

	/**
	 * Set key value with optional expiration
	 * Upstash uses options object: { ex: 60, px: 60000, exat: timestamp, pxat: timestamp }
	 */
	async set(
		key: string,
		value: any,
		opts?: { ex?: number; px?: number; exat?: number; pxat?: number }
	): Promise<any> {
		const args = [key, String(value)]

		if (opts?.px) {
			args.push('PX', String(opts.px))
		} else if (opts?.ex) {
			args.push('EX', String(opts.ex))
		} else if (opts?.pxat) {
			args.push('PXAT', String(opts.pxat))
		} else if (opts?.exat) {
			args.push('EXAT', String(opts.exat))
		}

		return await this.client.send('SET', args)
	}

	/**
	 * Check if multiple members exist in a set - used by deny list
	 * Redis: SMISMEMBER key member1 member2 ...
	 * Returns array of 0s and 1s (0 = not member, 1 = member)
	 */
	async smismember(key: string, ...members: string[]): Promise<number[]> {
		return await this.client.send('SMISMEMBER', [key, ...members])
	}

	/**
	 * Check if single member exists in set
	 * Returns 1 if member exists, 0 if not
	 */
	async sismember(key: string, member: string): Promise<number> {
		return await this.client.send('SISMEMBER', [key, member])
	}

	/**
	 * Add members to set
	 * Returns number of elements added
	 */
	async sadd(key: string, ...members: string[]): Promise<number> {
		return await this.client.send('SADD', [key, ...members])
	}

	/**
	 * Remove members from set
	 */
	async srem(key: string, ...members: string[]): Promise<number> {
		return await this.client.send('SREM', [key, ...members])
	}

	/**
	 * Get all members of a set
	 */
	async smembers(key: string): Promise<string[]> {
		return await this.client.send('SMEMBERS', [key])
	}

	/**
	 * Set difference and store result
	 * SDIFFSTORE destination key1 key2...
	 * Stores the difference of sets at keys into destination
	 */
	async sdiffstore(destination: string, ...keys: string[]): Promise<number> {
		return await this.client.send('SDIFFSTORE', [destination, ...keys])
	}

	/**
	 * Set union and store result
	 * SUNIONSTORE destination key1 key2...
	 * Stores the union of sets at keys into destination
	 */
	async sunionstore(destination: string, ...keys: string[]): Promise<number> {
		return await this.client.send('SUNIONSTORE', [destination, ...keys])
	}

	/**
	 * Increment key value
	 */
	async incr(key: string): Promise<number> {
		return await this.client.incr(key)
	}

	/**
	 * Increment by amount
	 */
	async incrby(key: string, increment: number): Promise<number> {
		return await this.client.send('INCRBY', [key, String(increment)])
	}

	/**
	 * Decrement key value
	 */
	async decr(key: string): Promise<number> {
		return await this.client.decr(key)
	}

	/**
	 * Delete keys
	 * Returns number of keys deleted
	 */
	async del(...keys: string[]): Promise<number> {
		return await this.client.del(...keys)
	}

	/**
	 * Check if keys exist
	 * Returns number of keys that exist
	 */
	async exists(...keys: string[]): Promise<number> {
		return await this.client.send('EXISTS', keys)
	}

	/**
	 * Set expiration in milliseconds
	 * Returns 1 if timeout was set, 0 if key doesn't exist
	 */
	async pexpire(key: string, milliseconds: number): Promise<number> {
		return await this.client.send('PEXPIRE', [key, String(milliseconds)])
	}

	/**
	 * Set expiration in seconds
	 */
	async expire(key: string, seconds: number): Promise<number> {
		return await this.client.expire(key, seconds)
	}

	/**
	 * Get time to live in milliseconds
	 * Returns TTL in milliseconds, or -1 if no expiry, -2 if key doesn't exist
	 */
	async pttl(key: string): Promise<number> {
		return await this.client.send('PTTL', [key])
	}

	/**
	 * Get time to live in seconds
	 * Returns TTL in seconds, or -1 if no expiry, -2 if key doesn't exist
	 */
	async ttl(key: string): Promise<number> {
		return await this.client.ttl(key)
	}

	/**
	 * Create a transaction pipeline (MULTI/EXEC)
	 *
	 * This uses Redis MULTI/EXEC for true atomic transactions.
	 * All commands queued between multi() and exec() are executed atomically.
	 *
	 * @example
	 * ```typescript
	 * const transaction = redis.multi()
	 * transaction.set("key1", "value1")
	 * transaction.incr("counter")
	 * transaction.del("key2")
	 * const results = await transaction.exec()
	 * ```
	 */
	multi() {
		const commands: Array<{ method: string; args: any[] }> = []
		const client = this.client

		const transaction = {
			/**
			 * Queue SDIFFSTORE command
			 */
			sdiffstore(destination: string, ...keys: string[]) {
				commands.push({ method: 'SDIFFSTORE', args: [destination, ...keys] })
				return transaction
			},

			/**
			 * Queue SADD command
			 */
			sadd(key: string, ...members: string[]) {
				commands.push({ method: 'SADD', args: [key, ...members] })
				return transaction
			},

			/**
			 * Queue DEL command
			 */
			del(...keys: string[]) {
				commands.push({ method: 'DEL', args: keys })
				return transaction
			},

			/**
			 * Queue SUNIONSTORE command
			 */
			sunionstore(destination: string, ...keys: string[]) {
				commands.push({ method: 'SUNIONSTORE', args: [destination, ...keys] })
				return transaction
			},

			/**
			 * Queue SET command with optional expiration
			 */
			set(key: string, value: any, opts?: { px?: number; ex?: number }) {
				const args = [key, String(value)]
				if (opts?.px) args.push('PX', String(opts.px))
				if (opts?.ex) args.push('EX', String(opts.ex))
				commands.push({ method: 'SET', args })
				return transaction
			},

			/**
			 * Queue SMEMBERS command
			 */
			smembers(key: string) {
				commands.push({ method: 'SMEMBERS', args: [key] })
				return transaction
			},

			/**
			 * Queue GET command
			 */
			get(key: string) {
				commands.push({ method: 'GET', args: [key] })
				return transaction
			},

			/**
			 * Queue TTL command
			 */
			ttl(key: string) {
				commands.push({ method: 'TTL', args: [key] })
				return transaction
			},

			/**
			 * Execute all queued commands atomically using Redis MULTI/EXEC
			 *
			 * This sends MULTI, then all queued commands, then EXEC to Redis.
			 * Redis executes all commands atomically - either all succeed or all fail.
			 * No other client can execute commands between MULTI and EXEC.
			 *
			 * @returns Array of results in the same order as commands were queued
			 */
			async exec() {
				// Start transaction
				await client.send('MULTI', [])

				// Queue all commands (Redis will respond with "QUEUED" for each)
				for (const cmd of commands) {
					await client.send(cmd.method, cmd.args as string[])
				}

				// Execute atomically and get results
				const results = await client.send('EXEC', [])
				return results
			}
		}

		return transaction
	}

	/**
	 * Get the underlying Bun Redis client
	 * Useful if you need to access Bun-specific features
	 */
	getClient(): RedisClient {
		return this.client
	}

	/**
	 * Close the Redis connection
	 */
	close(): void {
		this.client.close()
	}

	/**
	 * Check if connected to Redis
	 */
	get connected(): boolean {
		return this.client.connected
	}
}
