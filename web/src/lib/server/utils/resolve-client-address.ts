import type { RequestEvent } from '@sveltejs/kit'

/**
 * Resolve client IP from SvelteKit event.
 * Returns "unknown" when adapter address resolution throws or is empty.
 */
export function resolveClientAddress(event: RequestEvent): string {
	try {
		return event.getClientAddress() || 'unknown'
	} catch {
		console.warn('Could not resolve client address; getClientAddress() threw')

		return 'unknown'
	}
}
