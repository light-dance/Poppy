<script lang="ts">
	import { onMount, tick } from 'svelte'
	import * as v from 'valibot'
	import { getUser, startEmailChange } from '$remotes/auth/user.remote'
	import { createValidation, createEnhancedForm } from '@opensky/remotes'
	import { getDialogContext } from '../../dialog-context'

	import { createClass } from '@opensky/style'
	import { wipeVertical } from '$ui/transition'
	import { fade } from 'svelte/transition'
	import {
		IconUserCircle,
		IconArrowLeft,
		IconArrowBackUp,
		IconArrowRight,
		IconX
	} from '@tabler/icons-svelte'
	import { Dialog, Tooltip } from 'bits-ui'

	import { Suspense } from '$ui/feedback'
	import DialogHeader from '../../components/dialog-header.svelte'
	import VerificationCodeInput from './verification-code-input.svelte'

	// Context callbacks
	let { close }: { close: () => void } = $props()
	const { requireRecentAuth } = getDialogContext()

	// Get current user data
	let getUserPromise = $derived(getUser())
	let user = $derived(await getUserPromise)

	// Change email schema
	const startEmailChangeSchema = v.object({
		newEmail: v.pipe(
			v.string(),
			v.email('Invalid email address'),
			v.excludes(':', 'Invalid email address')
		),
		timezone: v.optional(v.string())
	})

	// Change email validator
	const startEmailChangeValid = createValidation(startEmailChange)
	// Change email form helper
	const startEmailChangeForm = createEnhancedForm(startEmailChange, {
		validation: startEmailChangeValid,
		delayMs: 100,
		timeoutMs: 9000
	})

	// Get local timezone for email absolute times
	const localTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone
	let emailInput = $state<HTMLInputElement>()

	// Error state
	let serverErrorMessage = $state<string | null>(null)
	let showError = $derived(
		!startEmailChangeForm.result &&
			(startEmailChangeForm.error ||
				(startEmailChangeValid.issues('newEmail') &&
					(startEmailChange.fields.newEmail.value()?.length ?? 0) > 0))
	)

	// Is email input different than users current email
	let emailDiff = $derived.by(() => {
		const current = startEmailChange.fields.newEmail.value()?.toLowerCase().trim() ?? ''
		return current !== user.identifier && current.length > 0
	})

	let startButtonAvailable = $derived(
		!startEmailChangeForm.result && !startEmailChangeValid.issues('newEmail') && emailDiff
	)

	const focusInput = () => {
		emailInput?.focus()
	}

	const revertEmail = () => {
		serverErrorMessage = null
		startEmailChange.fields.newEmail.set(user.identifier)
	}

	const resetForm = () => {
		const current = startEmailChange.result?.newEmail
		serverErrorMessage = null
		startEmailChangeForm.reset()
		startEmailChange.fields.newEmail.set(current ?? '')
	}

	const checkReauth = async () => {
		// Check recent auth
		const authed = await requireRecentAuth()
		// If not, then go back
		if (!authed) {
			close()
			return
		}
	}

	const onSuccess = async () => {
		await getUser().refresh()
		startEmailChangeForm.reset()
		startEmailChange.fields.newEmail.set(user.identifier)
	}

	const onUnrecoverableError = async () => {
		resetForm()
		await checkReauth()
	}

	onMount(async () => {
		await tick()
		startEmailChangeForm.reset()
		startEmailChange.fields.newEmail.set(user.identifier)
		focusInput()
	})
</script>

<div class="flex w-full flex-col justify-center p-3 text-neutral-200">
	<div class="flex w-full flex-col px-5 pt-7 pb-12">
		<DialogHeader
			title="Login Method"
			description="Change how you login to your account"
			icon={IconUserCircle}
			iconClasses="text-sky-500"
		/>

		<div class="flex w-full flex-col gap-5 py-1">
			<div>
				<!-- Label -->
				<div class="flex w-full items-baseline gap-2 px-5">
					<p class="pb-1 text-[0.94rem] font-semibold whitespace-nowrap text-neutral-400">
						Change Email
					</p>
				</div>

				<!-- Control -->
				<div
					class={createClass(
						'flex w-full flex-col items-center rounded-3xl bg-neutral-800/70 px-5 pr-3 focus-within:outline-2 focus-within:outline-blue-vibrant',
						showError && 'outline-2 outline-rose-600'
					)}
				>
					{#if !startEmailChangeForm.result}
						<!-- Email Input Step -->
						<form
							class="flex h-full w-full items-center py-2"
							{...startEmailChange.preflight(startEmailChangeSchema).enhance(async (opts) =>
								startEmailChangeForm.enhance(opts, {
									onSubmit() {
										serverErrorMessage = null
									},
									onError: async ({ error }) => {
										const err = error as { status?: number; body?: { message?: string } }

										const status = err?.status || 400
										const message: string | null = err?.body?.message || null

										if (status === 401) {
											await checkReauth()
										} else {
											serverErrorMessage = message
										}
									}
								})
							)}
						>
							<!-- Local timezone hidden input -->
							{#if localTimezone}
								<input
									{...startEmailChange.fields.timezone.as('hidden', localTimezone)}
									aria-hidden="true"
								/>
							{/if}

							<!-- New email input -->
							<input
								{...startEmailChange.fields.newEmail.as('email')}
								{...startEmailChangeValid.fields('newEmail')}
								bind:this={emailInput}
								oninput={() => (serverErrorMessage = null)}
								autocomplete="email"
								placeholder="Enter new email"
								class="h-full w-full shrink grow bg-transparent py-3 font-medium outline-none placeholder:text-neutral-600"
							/>

							<Tooltip.Provider delayDuration={350}>
								<!-- Undo button -->
								{#if emailDiff}
									<Tooltip.Root>
										<Tooltip.Trigger>
											<button
												type="button"
												onclick={revertEmail}
												class="flex items-center px-3 py-2 text-neutral-400 transition-transform hover:text-neutral-300"
											>
												<IconArrowBackUp />
											</button>
										</Tooltip.Trigger>
										<Tooltip.Content side="top" sideOffset={5} align="center">
											<div
												class="rounded-2xl bg-neutral-900 px-3 py-2 text-[0.9rem] font-semibold text-neutral-50"
											>
												Undo Change
											</div>
										</Tooltip.Content>
									</Tooltip.Root>
								{/if}

								<!-- Continue button -->
								<Tooltip.Root>
									<Tooltip.Trigger>
										{#if startEmailChangeForm.delayed}
											<Suspense.Spinner />
										{:else}
											<button
												type="submit"
												disabled={!startButtonAvailable}
												class={createClass(
													'rounded-full bg-linear-to-b px-5 py-2 transition-all active:scale-[0.97] disabled:cursor-not-allowed',
													startButtonAvailable
														? 'bg-blue-vibrant-light text-white shadow-[inset_0.5px_0.5px_0_rgba(255,255,255,0.3),inset_-0.5px_-0.5px_0_rgba(255,255,255,0.15)]'
														: 'bg-neutral-600 text-neutral-400 shadow-[inset_0.5px_0.5px_0_rgba(255,255,255,0.2),inset_-0.5px_-0.5px_0_rgba(255,255,255,0.1)]'
												)}
											>
												<IconArrowRight stroke={3} size={26} />
											</button>
										{/if}
									</Tooltip.Trigger>
									<Tooltip.Content side="top" sideOffset={5} align="center">
										<div
											class="rounded-2xl bg-neutral-900 px-3 py-2 text-[0.9rem] font-semibold text-neutral-50"
										>
											Change Email
										</div>
									</Tooltip.Content>
								</Tooltip.Root>
							</Tooltip.Provider>
						</form>

						<!-- Error display -->
						{#if showError && !startEmailChangeValid.issues('newEmail')}
							<div transition:wipeVertical class="w-full py-2.5">
								<button class="cursor-pointer font-[450] text-rose-500" onclick={focusInput}>
									{serverErrorMessage || 'Something went wrong, try again'}
								</button>
							</div>
						{:else if showError && startEmailChangeValid.issues('newEmail')}
							<div transition:wipeVertical class="flex w-full justify-start py-2.5">
								{#each startEmailChangeValid.issues('newEmail') ?? [] as issue (issue)}
									<button class="cursor-pointer font-[450] text-rose-500" onclick={focusInput}>
										{issue}
									</button>
								{/each}
							</div>
						{/if}
					{:else}
						<!-- Verification Step -->
						<div
							in:fade={{ duration: 350 }}
							class="flex w-full items-center justify-start gap-2 overflow-x-scroll py-3 pr-5 tabular-nums"
						>
							<button
								type="button"
								onclick={resetForm}
								class="group/button relative max-w-36 shrink rounded-xl bg-neutral-700/0 py-2 transition-colors delay-75 hover:bg-neutral-700"
							>
								<div
									class="pointer-events-none absolute inset-0 flex h-full w-full items-center gap-2 px-2 opacity-0 transition-opacity delay-75 duration-75 group-hover/button:opacity-100"
								>
									<IconX />
									<p>Cancel</p>
								</div>

								<p
									class="max-w-full truncate text-neutral-400 transition-opacity delay-75 duration-75 group-hover/button:opacity-0"
								>
									{user.identifier}
								</p>
							</button>
							<IconArrowRight size={23} class="text-neutral-300" />
							<p class="shrink-0 text-neutral-300 tabular-nums">
								{startEmailChange.result?.newEmail ?? 'Something went wrong'}
							</p>
						</div>

						<div
							in:wipeVertical
							class="group flex w-full items-center justify-between border-t border-neutral-700 py-3"
						>
							<VerificationCodeInput {onSuccess} {onUnrecoverableError} />
						</div>
					{/if}
				</div>
			</div>
		</div>
	</div>

	<!-- Buttons -->
	<div class="flex flex-col gap-2">
		<Dialog.Close
			class="group flex items-center justify-center gap-2 rounded-full py-4 text-[1.05rem] font-semibold text-white transition-transform hover:bg-neutral-800/70 active:scale-[0.97]"
		>
			<IconArrowLeft />
			Go Back
		</Dialog.Close>
	</div>
</div>
