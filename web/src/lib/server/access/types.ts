import type { RequestEvent } from '@sveltejs/kit'

// -- Check result returned by every resolve function --

export type CheckResult<T> = {
	value: T
	allowed: boolean
	message?: string
}

// -- Check definition --

type CheckResultOrPromise<T> = CheckResult<T> | Promise<CheckResult<T>>

export type CheckDefinition<T = unknown, Args extends unknown[] = []> = {
	resolve: (event: RequestEvent, ...args: Args) => CheckResultOrPromise<T>
	onDeny?: (event: RequestEvent, message: string) => never
}

/**
 * Defines an access check used by both
 * `Access.<rule>.check()` and `Access.<rule>.require()`
 *
 * @param definition - The check configuration
 * @returns The same definition, typed
 *
 * @example
 * // Check with optional args
 * export default defineCheck({
 *   resolve: async (event, level?: 'pro' | 'free') => {
 *     const plan = event.locals.access.plan ?? await fetchPlan(event)
 *     if (level === 'pro' && plan !== 'pro')
 *       return { value: plan, allowed: false, message: 'Pro required' }
 *     return { value: plan, allowed: true }
 *   }
 * })
 */
export function defineCheck<T, Args extends unknown[] = []>(definition: CheckDefinition<T, Args>) {
	return definition
}

// -- Access type for event.locals (hook-populated checks only) --

export type Access = {
	plan: 'pro' | 'free' | null
}
