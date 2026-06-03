// See https://svelte.dev/docs/kit/types#app.d.ts
// for information about these interfaces
import type { LockType, Session, User } from '$lib/server/auth/schema'
import type { AccessType as Access } from '$lib/server/access'

declare global {
	namespace App {
		// interface Error {}
		interface Locals {
			user: User | null
			session: Session | null
			userLocked: LockType[]
			access: Access
		}
		// interface PageData {}
		// interface PageState {}
		// interface Platform {}
	}
}

export {}
