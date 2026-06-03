<script lang="ts">
	import { playConfetti, playClick } from '$lib/components/audio'
	import { Button } from '$ui/input'

	let { data } = $props()

	let loggedIn = $derived(data.loggedIn ?? false)
</script>

<div class="mx-auto flex min-h-full max-w-160 flex-col gap-2 bg-neutral-50 px-6 py-8">
	<div class="W-full flex justify-end">
		<Button
			onClick={playClick}
			href="/login"
			style="primary"
			rounded="full"
			class="w-fit bg-neutral-600">{loggedIn ? 'App' : 'Login'}</Button
		>
	</div>

	<h1 class="text-lg font-medium">SvelteKit Example</h1>

	<div
		class="flex flex-col gap-2 py-3 text-[0.92rem]/5 font-medium tracking-[-0.01em] text-neutral-600"
	>
		<p>
			When testing auth, you can sign up with email and after creating an account can continue just
			using your email for a passwordless experience, or you can add a passkey.
		</p>
	</div>

	<Button
		onClick={playConfetti}
		style="primary"
		rounded="full"
		class="w-full bg-neutral-900 sm:w-fit"
	>
		Play confetti
	</Button>
</div>
