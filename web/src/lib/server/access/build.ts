import { error, type RequestEvent } from '@sveltejs/kit'

import type { CheckDefinition } from './types'

/**
 * Builds a rule object with `.check()` and `.require()` from a check definition
 * TypeScript infers the exact value type and args for full autocomplete
 *
 * @param definition - The check definition created with defineCheck()
 * @returns Object with `check` (returns full check result) and `require` (throws if denied)
 */
export function createRule<T, Args extends unknown[]>(definition: CheckDefinition<T, Args>) {
	const callResolve = (event: RequestEvent, args: Args) => definition.resolve(event, ...args)

	return {
		check: async (event: RequestEvent, ...args: Args) => {
			return await callResolve(event, args)
		},
		require: async (event: RequestEvent, ...args: Args) => {
			const result = await callResolve(event, args)

			if (!result.allowed) {
				const message = result.message || 'Access denied'
				if (definition.onDeny) {
					definition.onDeny(event, message)
				}
				throw error(403, message)
			}

			return result.value
		}
	}
}
