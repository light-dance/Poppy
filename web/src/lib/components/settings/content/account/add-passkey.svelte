<script lang="ts">
	import { startRegistration } from '@simplewebauthn/browser'
	import { startPasskeyRegistration, verifyPasskeyRegistration } from '$remotes/auth/passkey.remote'
	import { UAParser } from 'ua-parser-js'

	import { onMount } from 'svelte'
	import { createClass } from '@opensky/style'
	import { scale } from 'svelte/transition'
	import { IconX, IconArrowRight } from '@tabler/icons-svelte'
	import { AdaptSwap } from '$ui/adapt'
	import { SuspenseSpinner, SuspenseText } from '$ui/feedback'
	import { getDialogContext } from '../../dialog-context'

	let { close }: { close: () => void } = $props()

	const { requireRecentAuth } = getDialogContext()

	function getBrowserName(): string {
		const result = UAParser(navigator.userAgent)
		return result.browser.name || ''
	}

	let name = $state('')
	let nameInput = $state<HTMLElement>()

	let checkingAuth = $state(true)
	let pending = $state(false)
	let error = $state(false)

	onMount(async () => {
		const authed = await requireRecentAuth()

		if (!authed) {
			close()
			return
		}

		checkingAuth = false
		name = getBrowserName()
		await new Promise((r) => setTimeout(r, 0))
		nameInput?.focus()
		if (nameInput instanceof HTMLInputElement) {
			nameInput.select()
		}
	})

	async function addPasskey() {
		pending = true
		error = false

		try {
			const optionsResult = await startPasskeyRegistration().run()
			const registrationResponse = await startRegistration({ optionsJSON: optionsResult.options })
			const result = await verifyPasskeyRegistration({ name, registration: registrationResponse })

			pending = false

			if (result.success) {
				close()
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

<div class="flex w-full flex-col px-1 py-1">
	<div
		class="group flex w-full flex-col items-center rounded-3xl bg-neutral-900 px-2 pr-3 shadow-[inset_0.5px_0.5px_0_rgba(255,255,255,0.15),inset_-0.5px_-0.5px_0_rgba(255,255,255,0.15)] focus-within:outline-2 focus-within:outline-blue-vibrant"
	>
		{#if checkingAuth}
			<div class="flex w-full items-center justify-center gap-2 py-3">
				<SuspenseText class="py-1 text-lg font-medium" primaryColor="var(--color-white)"
					>One Moment...</SuspenseText
				>
			</div>
		{:else}
			<div class="flex w-full items-center gap-2 py-3">
				<button
					onclick={() => close()}
					class="ml-1 aspect-square rounded-full p-1.5 text-neutral-400 hover:bg-neutral-500 hover:text-neutral-100 active:scale-95"
				>
					<IconX />
				</button>

				<input
					type="text"
					bind:value={name}
					maxlength="64"
					bind:this={nameInput}
					placeholder="Passkey name"
					class="grow border-none font-medium outline-none"
				/>

				{#if error}
					<p class="pr-1.5 tracking-tight-md whitespace-nowrap text-rose-600">Error, try again</p>
				{/if}

				<AdaptSwap bind:isActive={pending}>
					<button
						onclick={async () => await addPasskey()}
						disabled={name.length < 3}
						class={createClass(
							'rounded-full px-5 py-1.5 text-[1.05rem] transition-all active:scale-[0.97]',
							name.length > 3
								? 'bg-blue-vibrant-light text-white shadow-[inset_0.5px_0.5px_0_rgba(255,255,255,0.3),inset_-0.5px_-0.5px_0_rgba(255,255,255,0.15)]'
								: 'bg-neutral-600 text-neutral-400 shadow-[inset_0.5px_0.5px_0_rgba(255,255,255,0.2),inset_-0.5px_-0.5px_0_rgba(255,255,255,0.1)]'
						)}
					>
						<IconArrowRight stroke={3} size={26} />
					</button>

					{#snippet swapContent()}
						<div
							in:scale={{ start: 0.5, opacity: 0.3 }}
							class="rounded-full bg-blue-vibrant-light px-5 py-2"
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
		{/if}
	</div>
</div>
