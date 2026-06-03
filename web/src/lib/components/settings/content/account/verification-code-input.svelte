<script lang="ts">
	import { onMount, tick } from 'svelte'
	import { verifyEmailChange } from '$remotes/auth/user.remote'
	import { createEnhancedForm } from '@opensky/remotes'

	import { delay } from '$utils/timing'
	import { createClass } from '@opensky/style'
	import { createShake } from '$lib/components/adapt/shake-behavior'
	import { scale } from 'svelte/transition'
	import { IconCircleCheck } from '@tabler/icons-svelte'
	import { PinInput, REGEXP_ONLY_DIGITS, type PinInputRootSnippetProps } from 'bits-ui'
	import { AdaptReveal } from '$ui/adapt'

	import { Suspense } from '$ui/feedback'

	let {
		onSuccess,
		onUnrecoverableError
	}: {
		onSuccess: () => void
		onUnrecoverableError: () => void
	} = $props()

	// Verify Email Change Form
	const verifyEmailChangeForm = createEnhancedForm(verifyEmailChange, {
		delayMs: 150,
		timeoutMs: 9000
	})
	let verifyEmailChangeFormElement = $state<HTMLFormElement>()
	let codeValue = $state('')

	type CellProps = PinInputRootSnippetProps['cells'][0]

	const { translateX, triggerShake } = createShake({
		amplitude: 14,
		shakes: 3,
		duration: 350
	})

	let resultSuccess = $derived(verifyEmailChangeForm.result && verifyEmailChange?.result?.success)
	let resultError = $derived(verifyEmailChangeForm.error && codeValue === '')

	let triggerErrorToast = $state<(() => void) | null>(null)
	let triggerSentToast = $state<(() => void) | null>(null)

	onMount(async () => {
		await tick()
		codeValue = ''
		verifyEmailChangeForm.reset()
		triggerSentToast?.()
	})
</script>

<div class="flex gap-2">
	<p class="shrink-0 text-[1.05rem] font-medium">Verify Email</p>
	<AdaptReveal bind:trigger={triggerErrorToast} durationMs={5000}>
		<p transition:scale class="text-rose-600">Code invalid</p>
	</AdaptReveal>
	<AdaptReveal bind:trigger={triggerSentToast}>
		<p transition:scale={{ start: 0.5, duration: 300 }} class="font-medium text-neutral-400">
			Code Sent
		</p>
	</AdaptReveal>
</div>

<!-- Hidden form element for the code input validation -->
<form
	bind:this={verifyEmailChangeFormElement}
	class="hidden"
	aria-hidden="true"
	{...verifyEmailChange.enhance(async (opts) =>
		verifyEmailChangeForm.enhance(opts, {
			onReturn: async ({ result }) => {
				if (result.success) {
					await delay(3000)
					onSuccess()
				}
			},
			onError: async ({ error }) => {
				codeValue = ''

				const err = error as { status?: number }
				const status = err?.status

				if (status === 401) {
					onUnrecoverableError() // Reauth required
				} else if (status === 400) {
					onUnrecoverableError() // Issue with request
				} else {
					triggerShake()
					triggerErrorToast?.()
					await delay(1300)
					verifyEmailChangeForm.reset()
				}
			}
		})
	)}
>
	<input
		{...verifyEmailChange.fields.code.as('text')}
		autocomplete="one-time-code"
		inputmode="numeric"
		maxlength="6"
		value={codeValue}
	/>
</form>

<div class="flex flex-col items-center" in:scale={{ start: 0.7 }}>
	<div style:transform="translateX({$translateX}px)">
		<PinInput.Root
			onComplete={() => verifyEmailChangeFormElement?.requestSubmit()}
			bind:value={codeValue}
			maxlength={6}
			pattern={REGEXP_ONLY_DIGITS}
			class={createClass(
				'group relative flex w-fit cursor-pointer items-center justify-start overflow-hidden py-1 pr-2 has-disabled:opacity-70'
			)}
		>
			{#snippet children({ cells })}
				<!-- Pending State -->
				<div
					class={createClass(
						'absolute inset-0 z-10 flex h-full w-full items-center justify-center transition-all delay-100 duration-300',
						verifyEmailChangeForm.pending || verifyEmailChangeForm.delayed
							? 'scale-100 opacity-100'
							: 'scale-80 opacity-0'
					)}
				>
					<Suspense.Text
						class="text-[1.1rem] font-medium"
						backgroundColor="var(--color-neutral-600)"
						primaryColor="var(--color-neutral-200)"
					>
						Verifying...
					</Suspense.Text>
				</div>
				<!-- Success State -->
				<div
					class={createClass(
						'absolute inset-0 z-10 flex h-full w-full items-center justify-center rounded-xl transition-all duration-150',
						resultSuccess ? 'translate-y-0 opacity-100' : 'translate-y-full opacity-0'
					)}
				>
					<div class={createClass('flex h-full w-full items-center justify-center')}>
						<IconCircleCheck class="text-green-500" />
						<p class="font-medium tracking-tight-md text-green-500">Verified</p>
					</div>
				</div>
				<!-- Pin Input -->
				<div class="flex">
					<!-- eslint-disable-next-line svelte/require-each-key -->
					{#each cells.slice(0, 3) as cell}
						{@render Cell(cell)}
					{/each}
				</div>

				<div class="flex w-4 items-center justify-center"></div>

				<div class="flex">
					<!-- eslint-disable-next-line svelte/require-each-key -->
					{#each cells.slice(3, 6) as cell}
						{@render Cell(cell)}
					{/each}
				</div>
			{/snippet}
		</PinInput.Root>
	</div>
</div>

{#snippet Cell(cell: CellProps)}
	<PinInput.Cell
		{cell}
		class={createClass(
			'group/cell relative flex h-10 w-5 cursor-pointer items-center justify-center rounded-xl transition-all duration-500',
			cell.char !== null && 'data-active:bg-sky-400/10',
			verifyEmailChangeForm.pending || verifyEmailChangeForm.delayed || resultSuccess
				? 'scale-110 opacity-0 blur-md'
				: 'scale-100 opacity-100 blur-none'
		)}
	>
		<!-- Cell placeholder (swaps) -->
		<div class="absolute top-0 left-0 flex h-full w-full items-center justify-center">
			<div
				style:opacity={cell.char === null ? '1.0' : '0.0'}
				style:transform={cell.char === null
					? 'translateY(0%) scaleY(1)'
					: 'translateY(150%) scaleY(3)'}
				class={createClass(
					'text-xl font-semibold transition-all duration-200',
					cell.hasFakeCaret && 'text-blue-500 text-shadow-blue-vibrant-light',
					!cell.hasFakeCaret &&
						!resultError &&
						'text-neutral-600 group-hover:text-neutral-500 group-hover:group-focus-within:text-neutral-600',
					!cell.hasFakeCaret &&
						resultError &&
						'text-rose-600 group-focus-within:text-neutral-600 group-hover:text-rose-600 group-hover:group-focus-within:text-neutral-600'
				)}
			>
				0
			</div>
		</div>
		<!-- Active cell text -->
		<div
			style:opacity={cell.char !== null ? '1.0' : '0.0'}
			style:transform={cell.char !== null ? 'translateY(0%)' : 'translateY(-50%)'}
			style:filter={cell.char !== null ? 'blur(0px)' : 'blur(5px)'}
			class="text-xl font-medium transition-all duration-300 group-data-active/cell:text-blue-500"
		>
			{cell.char}
		</div>
	</PinInput.Cell>
{/snippet}
