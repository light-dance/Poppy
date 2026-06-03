<script lang="ts">
	import type { Snippet } from 'svelte'
	import { createClass } from '@opensky/style'

	import { handleLogout } from '$ui/auth/logout'

	interface Props {
		/** Content to be displayed with adaptive sizing */
		children?: Snippet
		/** CSS class for the container */
		class?: string
		/** CSS classes applied when in error state */
		errorClass?: string
		/** Bindable state var for an error having occurred */
		error?: boolean
	}

	let { children, class: classProp, errorClass, error = $bindable() }: Props = $props()
</script>

<button
	onclick={async () => {
		try {
			await handleLogout()
		} catch {
			console.error('Failed to logout')
		}
	}}
	class={createClass(classProp, error && errorClass)}
>
	{#if children}
		{@render children()}
	{:else}
		Logout
	{/if}
</button>
