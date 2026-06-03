<script lang="ts">
	import { onMount, tick } from 'svelte'
	import { startLoginPasskey, verifyLoginPasskey } from '$remotes/auth/authenticate.remote'
	import { startAuthentication } from '@simplewebauthn/browser'

	import { createClass } from '@opensky/style'
	import { scale } from 'svelte/transition'

	import { IconReload } from '@tabler/icons-svelte'
	import IconPasskey from './passkey-icon.svelte'
	import { Suspense } from '$ui/feedback'
	import { handleLoginSuccess } from './login-user'

	type Props = {
		identifier?: string
		auto?: boolean
		reauth?: boolean
		onSuccess?: () => void
	}
	let { identifier, auto = true, reauth = false, onSuccess }: Props = $props()

	type ButtonState = 'idle' | 'pending' | 'result' | 'error'
	let buttonState = $state<ButtonState>('idle')

	async function handleClick() {
		if (buttonState === 'idle') {
			await tryLoginPasskey()
		} else if (buttonState === 'pending') {
			buttonState = 'idle'
			// cancel attempt?
		} else if (buttonState === 'error') {
			buttonState = 'idle'
			await tryLoginPasskey()
		}
	}

	async function tryLoginPasskey() {
		buttonState = 'pending'

		try {
			const optionsResult = await startLoginPasskey({ identifier }).run()

			const authenticationResponse = await startAuthentication({
				optionsJSON: optionsResult.options
			})

			const result = await verifyLoginPasskey({ attestation: authenticationResponse })

			if (result.success) {
				buttonState = 'result'

				if (reauth && onSuccess) {
					onSuccess()
				} else if (result.redirectUrl) {
					handleLoginSuccess(result.redirectUrl)
				}
			}
		} catch (e) {
			console.error(e)
			buttonState = 'error'
		}
	}

	onMount(async () => {
		if (auto) {
			await tick()
			await tryLoginPasskey()
		}
	})
</script>

<div class="flex w-full flex-col items-center justify-center">
	<button
		onclick={handleClick}
		class={createClass(
			'flex cursor-pointer items-center justify-center gap-2 bg-blue-vibrant-light py-3 font-medium text-white transition-all outline-none',
			buttonState === 'idle' ? 'rounded-[1.2rem] px-10' : 'my-2 rounded-4xl px-4',
			buttonState === 'error' &&
				'rounded-[1.2rem] bg-neutral-600 text-neutral-100 group-data-dark/reauth:bg-neutral-700'
		)}
	>
		{#if buttonState === 'idle'}
			<IconPasskey />
			<p>Use Passkey</p>
		{:else if buttonState === 'pending' || buttonState === 'result'}
			<Suspense.Spinner
				size={14}
				thickness={10}
				speed="fast"
				primaryColor="var(--color-neutral-100)"
				backgroundColor="var(--color-blue-vibrant-light)"
			/>
			<Suspense.Text
				class="text-md text-[1rem] font-[450]"
				spread={13}
				backgroundColor="var(--color-sky-200)"
				primaryColor="var(--color-white)">Trying Passkey</Suspense.Text
			>
		{:else}
			<IconReload stroke={2.5} size={19} />
			<p>Retry Passkey</p>
		{/if}
	</button>

	{#if buttonState === 'error'}
		<div class="px-5" in:scale={{ start: 0.8, opacity: 0.7, duration: 300 }}>
			<div class="flex max-w-56 flex-col items-start justify-start">
				<div class="flex items-center gap-1">
					<p class="font-medium text-rose-500">Error. Please try again</p>
				</div>
			</div>
		</div>
	{/if}
</div>
