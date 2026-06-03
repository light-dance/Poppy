import type { Handle, RequestEvent } from '@sveltejs/kit'

import type { CheckResult } from './types'

type AccessLocalResolver<T> = (event: RequestEvent) => T | Promise<T>
type AccessLocalResolverMap = Record<string, AccessLocalResolver<unknown>>
type AccessLocals<TLocalResolvers extends AccessLocalResolverMap> = {
	[K in keyof TLocalResolvers]: Awaited<ReturnType<TLocalResolvers[K]>> | null
}

type HookCheck<T> = {
	resolve: (event: RequestEvent) => CheckResult<T> | Promise<CheckResult<T>>
}

/**
 * Builds a hook local resolver from a check definition
 *
 * @param check - Check with an event-only resolve signature
 * @returns Resolver that returns only the check value
 */
export function createLocal<T>(check: HookCheck<T>) {
	return async (event: RequestEvent) => {
		const result = await check.resolve(event)
		return result.value
	}
}

/**
 * Builds a SvelteKit handle hook that populates event.locals.access
 * with values resolved by the provided local resolvers
 *
 * @param localResolvers - Access local resolvers keyed by access property
 * @returns Handle hook
 */
export function createAccessHandle<TLocalResolvers extends AccessLocalResolverMap>(
	localResolvers: TLocalResolvers
) {
	return (async ({ event, resolve }) => {
		const keys = Object.keys(localResolvers) as Array<keyof TLocalResolvers>

		const access = Object.fromEntries(
			keys.map((key) => [key, null])
		) as AccessLocals<TLocalResolvers>

		// Make access available to checks while the hook resolves values
		event.locals.access = access as App.Locals['access']

		// Resolve access values in parallel for authenticated users
		if (event.locals.user) {
			const resolvedEntries = await Promise.all(
				keys.map(async (key) => [key, await localResolvers[key](event)] as const)
			)

			for (const [key, value] of resolvedEntries) {
				access[key] = value as AccessLocals<TLocalResolvers>[typeof key]
			}
		}

		return resolve(event)
	}) satisfies Handle
}
