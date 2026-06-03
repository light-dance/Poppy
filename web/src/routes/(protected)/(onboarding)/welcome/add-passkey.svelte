<script lang="ts">
	import { startRegistration } from '@simplewebauthn/browser'
	import { startPasskeyRegistration, verifyPasskeyRegistration } from '$remotes/auth/passkey.remote'
	import { UAParser } from 'ua-parser-js'

	import { createClass } from '@opensky/style'
	import { scale } from 'svelte/transition'
	import { IconX, IconArrowRight, IconCheck } from '@tabler/icons-svelte'
	import { AdaptSwap } from '$ui/adapt'
	import { SuspenseSpinner } from '$ui/feedback'
	import IconPasskey from '$lib/components/auth/passkey-icon.svelte'

	function getBrowserName(): string {
		const result = UAParser(navigator.userAgent)
		return result.browser.name || ''
	}

	let isAdding = $state(false)
	let name = $state('')
	let nameInput = $state<HTMLElement>()

	let pending = $state(false)
	let error = $state(false)
	let success = $state(false)

	function startAdding() {
		isAdding = true
		name = getBrowserName()
		// Focus input after transition
		setTimeout(() => {
			nameInput?.focus()
			// Select all text so user can easily replace
			if (nameInput instanceof HTMLInputElement) {
				nameInput.select()
			}
		}, 100)
	}

	function cancel() {
		isAdding = false
		name = ''
		error = false
	}

	async function addPasskey() {
		pending = true
		error = false

		try {
			const optionsResult = await startPasskeyRegistration().run()
			const registrationResponse = await startRegistration({ optionsJSON: optionsResult.options })
			const result = await verifyPasskeyRegistration({ name, registration: registrationResponse })

			pending = false

			if (result.success) {
				success = true
			} else {
				error = true
			}
		} catch (e) {
			console.error('Failed to add passkey', e)
			pending = false
			error = true
		}
	}
</script>

<div class="flex w-full flex-col items-center gap-4 pt-1">
	<!-- Header -->
	<div class="flex flex-col items-center gap-1">
		<h3 class="text-lg font-semibold text-neutral-100">Secure your account</h3>
		<p class="max-w-xs text-center text-sm text-neutral-500">
			Passkeys are the easiest and most secure way to sign in. No passwords to remember.
		</p>
	</div>

	{#if success}
		<div
			class="flex items-center gap-2 rounded-full bg-emerald-900/50 px-5 py-3 text-emerald-400"
			in:scale={{ start: 0.9, duration: 150 }}
		>
			<IconCheck size={20} />
			<span class="font-medium">Passkey added</span>
		</div>
	{:else if !isAdding}
		<button
			onclick={startAdding}
			class="flex items-center justify-center gap-2 rounded-[1.2rem] bg-blue-vibrant-light px-10 py-3 font-medium text-white transition-all active:scale-[0.98]"
		>
			<IconPasskey />
			<span>Add a Passkey</span>
		</button>
	{:else}
		<div
			class="flex w-full flex-col items-center gap-2 rounded-3xl bg-neutral-800 px-3 py-3"
			in:scale={{ start: 0.95, duration: 150 }}
		>
			<div class="flex w-full items-center gap-2">
				<button
					onclick={cancel}
					class="aspect-square shrink-0 rounded-full p-2 text-neutral-400 hover:bg-neutral-700 hover:text-neutral-100 active:scale-95"
				>
					<IconX size={20} />
				</button>

				<input
					type="text"
					bind:value={name}
					maxlength="64"
					bind:this={nameInput}
					placeholder="Passkey name"
					class="min-w-0 grow border-none bg-transparent font-medium text-white outline-none placeholder:text-neutral-500"
				/>

				<AdaptSwap bind:isActive={pending}>
					<button
						onclick={async () => await addPasskey()}
						disabled={name.length < 3}
						class={createClass(
							'shrink-0 rounded-full px-4 py-2 transition-all active:scale-[0.97]',
							name.length >= 3
								? 'bg-blue-vibrant-light text-white shadow-[inset_0.5px_0.5px_0_rgba(255,255,255,0.3),inset_-0.5px_-0.5px_0_rgba(255,255,255,0.15)]'
								: 'bg-neutral-700 text-neutral-500'
						)}
					>
						<IconArrowRight stroke={2.5} size={22} />
					</button>

					{#snippet swapContent()}
						<div
							in:scale={{ start: 0.5, opacity: 0.3 }}
							class="rounded-full bg-blue-vibrant-light px-4 py-2.5"
						>
							<SuspenseSpinner
								size={14}
								thickness={10}
								speed="fast"
								primaryColor="var(--color-neutral-100)"
								backgroundColor="var(--color-blue-vibrant-light)"
							/>
						</div>
					{/snippet}
				</AdaptSwap>
			</div>

			{#if error}
				<p class="text-sm text-rose-500">Error, try again</p>
			{/if}
		</div>
	{/if}
</div>
