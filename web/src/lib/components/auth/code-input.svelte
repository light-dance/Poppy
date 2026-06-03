<script lang="ts">
	import { onMount, tick } from 'svelte'
	import { sendLoginCode, sendReauthCode, verifyLoginCode } from '$remotes/auth/authenticate.remote'
	import { createEnhancedForm } from '@opensky/remotes'

	import { delay } from '$utils/timing'
	import { createClass } from '@opensky/style'
	import { createShake } from '$lib/components/adapt/shake-behavior'
	import { scale } from 'svelte/transition'
	import { IconCircleCheck, IconCircleCheckFilled } from '@tabler/icons-svelte'
	import { PinInput, REGEXP_ONLY_DIGITS, type PinInputRootSnippetProps } from 'bits-ui'

	import { Suspense } from '$ui/feedback'
	import ResendEmailButton from './resend-email-button.svelte'
	import { handleLoginSuccess } from './login-user'

	type Props = {
		codeSent: boolean
		identifier: string
		timezone: string
		dark?: boolean
		reauth?: boolean
		onSuccess?: () => void
	}
	let {
		codeSent: codeSentInitially = false,
		identifier,
		timezone,
		dark = false,
		reauth = false,
		onSuccess
	}: Props = $props()

	// Send Code Forms
	//
	const sendLoginCodeForm = createEnhancedForm(sendLoginCode, {
		delayMs: 50,
		timeoutMs: 5000
	})
	const sendReauthCodeForm = createEnhancedForm(sendReauthCode, {
		delayMs: 50,
		timeoutMs: 5000
	})
	// svelte-ignore state_referenced_locally
	const sendCodeForm = reauth ? sendReauthCodeForm : sendLoginCodeForm
	let sendLoginCodeFormElement = $state<HTMLFormElement>()
	let sendReauthCodeFormElement = $state<HTMLFormElement>()

	// svelte-ignore state_referenced_locally
	let codeSent = $state(codeSentInitially)
	let emailSentSuccessToast = $state(false)

	const triggerSuccessToast = async () => {
		emailSentSuccessToast = true
		await delay(3500)
		emailSentSuccessToast = false
	}

	// Login with Code
	//
	const verifyLoginCodeForm = createEnhancedForm(verifyLoginCode, {
		delayMs: 150,
		timeoutMs: 5000
	})
	let verifyLoginCodeFormElement = $state<HTMLFormElement>()
	let codeValue = $state('')
	type CellProps = PinInputRootSnippetProps['cells'][0]

	const { translateX, triggerShake } = createShake({
		amplitude: 14,
		shakes: 3,
		duration: 350
	})

	let resultSuccess = $derived(verifyLoginCodeForm.result && verifyLoginCode?.result?.success)

	let resultError = $derived(verifyLoginCode?.result?.success === false && codeValue === '')

	//
	// Reset form on component mount
	onMount(async () => {
		await tick()

		codeValue = ''
		verifyLoginCodeForm.reset()

		if (codeSentInitially) {
			triggerSuccessToast()
		}
	})
</script>

{#if codeSent}
	<!-- Hidden form element for the code input validation -->
	<form
		bind:this={verifyLoginCodeFormElement}
		class="hidden"
		aria-hidden="true"
		{...verifyLoginCode.enhance(async (opts) =>
			verifyLoginCodeForm.enhance(opts, {
				onReturn: async ({ result }) => {
					if (result.success === false) {
						codeValue = ''
						triggerShake()
						await delay(1300)
						verifyLoginCodeForm.reset()
					} else if (result.success === true) {
						if (reauth && onSuccess) {
							onSuccess()
						} else if (result.redirectUrl) {
							handleLoginSuccess(result.redirectUrl)
						}
					}
				},
				onError: async () => {
					codeValue = ''
					triggerShake()
					await delay(1300)
					verifyLoginCodeForm.reset()
				}
			})
		)}
	>
		<input
			{...verifyLoginCode.fields.code.as('text')}
			autocomplete="one-time-code"
			inputmode="numeric"
			maxlength="6"
			value={codeValue}
		/>
	</form>

	<div class="flex flex-col items-center" in:scale={{ start: 0.7 }}>
		<p
			class={createClass(
				'h-8 pb-2',
				resultError
					? 'text-[0.9rem] font-[450] text-rose-600'
					: 'text-[1.02rem] group-data-dark/reauth:text-neutral-400'
			)}
		>
			{resultError ? 'Code invalid, try again' : 'Enter Code'}
		</p>

		<div style:transform="translateX({$translateX}px)">
			<PinInput.Root
				onComplete={() => !verifyLoginCode.pending && verifyLoginCodeFormElement?.requestSubmit()}
				bind:value={codeValue}
				maxlength={6}
				pattern={REGEXP_ONLY_DIGITS}
				class={createClass(
					'group flex w-fit cursor-pointer items-center overflow-hidden rounded-[1.2rem] bg-gray-100 px-5 py-1 group-data-dark/reauth:bg-neutral-800 has-disabled:opacity-70',
					'focus-within:outline-2 focus-within:outline-blue-500 group-data-dark/reauth:focus-within:outline-blue-vibrant',
					verifyLoginCodeForm.pending && 'bg-blue-200/30 focus-within:outline-none',
					resultSuccess && 'outline-2 outline-green-500 focus-within:outline-green-500',
					resultError && 'outline-2 outline-rose-500 focus-within:outline-rose-500'
				)}
			>
				{#snippet children({ cells })}
					<!-- Pending State -->
					<div
						class={createClass(
							'absolute inset-0 flex h-full w-full items-center justify-center transition-all delay-100 duration-300',
							verifyLoginCodeForm.pending ? 'scale-100 opacity-100' : 'scale-80 opacity-0'
						)}
					>
						<Suspense.Text class="text-[1.1rem] font-medium">Trying Code...</Suspense.Text>
					</div>
					<!-- Success State -->
					<div
						class={createClass(
							'absolute inset-0 z-10 flex h-full w-full items-center justify-center rounded-xl transition-all duration-150',
							resultSuccess
								? 'translate-y-0 bg-green-200/40 opacity-100 backdrop-blur'
								: 'translate-y-full bg-transparent opacity-0 backdrop-blur-none'
						)}
					>
						<div class={createClass('flex h-full w-full items-center justify-center')}>
							<IconCircleCheck class="text-green-600" />
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

			<!-- Pin input snippet for each input character -->
			{#snippet Cell(cell: CellProps)}
				<PinInput.Cell
					{cell}
					class={createClass(
						'group/cell relative flex h-10 w-5 cursor-pointer items-center justify-center rounded-xl transition-all duration-500 group-data-dark/reauth:text-neutral-200',
						cell.char !== null && 'data-active:bg-sky-400/10',
						verifyLoginCodeForm.pending
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
								`text-xl font-semibold transition-all duration-200`,
								cell.hasFakeCaret
									? 'text-blue-vibrant-light'
									: 'text-neutral-400 group-hover:text-neutral-600 group-hover:group-focus-within:text-neutral-400 group-data-dark/reauth:text-neutral-600 group-data-dark/reauth:group-hover:text-neutral-500 group-data-dark/reauth:group-hover:group-focus-within:text-neutral-500'
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
		</div>
	</div>
{/if}

<!-- Hidden form element for requesting to send login code -->
{#if reauth}
	<form
		bind:this={sendReauthCodeFormElement}
		class="hidden"
		aria-hidden="true"
		{...sendReauthCode.enhance((opts) =>
			sendReauthCodeForm.enhance(opts, {
				onReturn: async () => {
					codeSent = true
					await triggerSuccessToast()
				},
				onError: () => {
					console.log('error')
				}
			})
		)}
	>
		<input {...sendReauthCode.fields.timezone.as('hidden', timezone)} />
	</form>
{:else}
	<form
		bind:this={sendLoginCodeFormElement}
		class="hidden"
		aria-hidden="true"
		{...sendLoginCode.enhance((opts) =>
			sendLoginCodeForm.enhance(opts, {
				onReturn: async () => {
					codeSent = true
					await triggerSuccessToast()
				},
				onError: () => {
					console.log('error')
				}
			})
		)}
	>
		<input {...sendLoginCode.fields.identifier.as('hidden', identifier)} />
		<input {...sendLoginCode.fields.timezone.as('hidden', timezone)} />
	</form>
{/if}

{#if sendCodeForm.error || sendCodeForm.issues || sendCodeForm.timeout}
	<p class="font-[450] text-rose-500">Failed sending email. Try again</p>
{/if}

<div class="flex h-12 w-full items-center justify-center">
	{#if emailSentSuccessToast}
		<div class="flex items-center gap-1 whitespace-nowrap" in:scale>
			<IconCircleCheckFilled size={19} class="text-green-600" />
			<p class="font-medium tracking-tight text-green-600">Email Sent</p>
		</div>
	{:else if sendCodeForm.delayed}
		<div class="flex items-center gap-4" in:scale>
			<Suspense.Text
				class="font-medium"
				backgroundColor={dark ? 'var(--color-neutral-600)' : undefined}
				primaryColor={dark ? 'var(--color-neutral-200)' : undefined}
			>
				Sending Email
			</Suspense.Text>
		</div>
	{:else if !codeSentInitially && !codeSent}
		<button
			onclick={() => {
				if (reauth) {
					sendReauthCodeFormElement?.requestSubmit()
				} else {
					sendLoginCodeFormElement?.requestSubmit()
				}
			}}
			class="group rounded-full bg-none px-4 py-2 font-medium text-neutral-500 transition-all group-data-dark/reauth:text-neutral-400 hover:bg-neutral-100 group-data-dark/reauth:hover:bg-neutral-800 active:scale-95"
		>
			or <span
				class="text-neutral-700 group-data-dark/reauth:text-neutral-200 group-data-dark/reauth:group-hover:text-white hover:text-black"
				>login with email</span
			>
		</button>
	{:else}
		<div in:scale={{ duration: 300 }}>
			<ResendEmailButton
				cooldownMs={20 * 1000}
				onclick={() => {
					if (reauth) {
						sendReauthCodeFormElement?.requestSubmit()
					} else {
						sendLoginCodeFormElement?.requestSubmit()
					}
				}}
				{dark}
			/>
		</div>
	{/if}
</div>
