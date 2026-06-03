<script lang="ts">
	import { goto } from '$app/navigation'
	import { onMount, tick } from 'svelte'
	import * as v from 'valibot'
	import { useSearchParams } from 'runed/kit'
	import { Bot } from '@lucide/svelte'
	import {
		IconShieldLock,
		IconHandStop,
		IconArrowRight,
		IconChevronLeft
	} from '@tabler/icons-svelte'
	import { Tooltip } from 'bits-ui'

	import { createEnhancedForm, createValidation } from '@opensky/remotes'
	import { createClass } from '@opensky/style'
	import type { Lock } from '$lib/server/auth/schema'
	import { formatDate } from '$lib/utils/datetime'
	import {
		createUserLock,
		getUserLocks,
		startUserLockLookup,
		resolveUserLock,
		updateUserLockReason
	} from '$remotes/auth/lock.remote'

	import LockRow from './lock.svelte'
	import TimelineEntry from './timeline-entry.svelte'

	type UserLockState = {
		user: {
			id: string
			identifier: string
			name: string
		}
	}

	const startUserLockLookupSchema = v.object({
		identifier: v.pipe(v.string(), v.email('Invalid email address'))
	})
	const userLockoutSearchParamsSchema = v.object({
		identifier: v.fallback(v.pipe(v.string(), v.email()), '')
	})
	const startUserLockLookupValid = createValidation(startUserLockLookup)
	const startUserLockLookupForm = createEnhancedForm(startUserLockLookup, {
		validation: startUserLockLookupValid,
		delayMs: 100,
		timeoutMs: 9000
	})
	const userLockoutSearchParams = useSearchParams(userLockoutSearchParamsSchema, {
		pushHistory: false
	})

	let selectedUserLockState = $state<UserLockState | null>(null)
	let hasSelectedIdentifier = $derived(Boolean(selectedUserLockState))
	let serverErrorMessage = $state<string | null>(null)
	let lookupFormElement = $state<HTMLFormElement | null>(null)
	let selectedUserId = $derived(selectedUserLockState?.user.id ?? null)
	let lockHistoryQuery = $derived(selectedUserId ? getUserLocks(selectedUserId) : null)
	let lockHistory = $derived(lockHistoryQuery?.current ?? [])
	let activeLocks = $derived(lockHistory.filter((lock) => !lock.unlockedAt))
	const lockTypes: Lock['type'][] = ['bot', 'security', 'ban']

	let lockRows = $derived(
		lockTypes.map((type) => {
			const activeLock = activeLocks.find((lock) => lock.type === type)
			const latestLock = lockHistory.find((lock) => lock.type === type)

			return {
				type,
				isActive: Boolean(activeLock),
				date: activeLock?.lockedAt ?? latestLock?.lockedAt ?? null
			}
		})
	)

	let canContinue = $derived(
		!selectedUserLockState &&
			!startUserLockLookupValid.issues('identifier') &&
			(startUserLockLookup.fields.value()?.identifier?.trim().length ?? 0) > 0
	)

	function getLockTypeLabel(type: Lock['type']) {
		if (type === 'bot') return 'Flagged as bot'
		if (type === 'security') return 'Lock for security'
		return 'Banned'
	}

	function getRelativeDate(date: Date | string) {
		return formatDate(new Date(date), { weekday: true }).date.relative
	}

	function getLockRow(type: Lock['type']) {
		return (
			lockRows.find((lockRow) => lockRow.type === type) ?? {
				type,
				isActive: false,
				date: null
			}
		)
	}

	let botLockRow = $derived(getLockRow('bot'))
	let securityLockRow = $derived(getLockRow('security'))
	let banLockRow = $derived(getLockRow('ban'))

	// Restore selected user state when returning with an identifier in the URL.
	onMount(async () => {
		const identifierFromSearchParams = userLockoutSearchParams.identifier.trim()

		if (!identifierFromSearchParams) return

		startUserLockLookup.fields.identifier.set(identifierFromSearchParams)
		await tick()
		lookupFormElement?.requestSubmit()
	})

	function resetIdentifier() {
		const currentIdentifier = selectedUserLockState?.user.identifier ?? ''

		startUserLockLookupForm.reset()
		selectedUserLockState = null
		userLockoutSearchParams.identifier = ''
		startUserLockLookup.fields.identifier.set(currentIdentifier)
		serverErrorMessage = null
	}

	async function copyIdentifier() {
		await navigator.clipboard.writeText(selectedUserLockState?.user.identifier ?? '')
	}

	async function gotoReauthRoute(reauthRoute: string) {
		// Reauth routes come from trusted server config and are not static literals.
		// eslint-disable-next-line svelte/no-navigation-without-resolve
		await goto(reauthRoute)
	}

	async function onLockRowAction(type: Lock['type']) {
		const user = selectedUserLockState?.user

		if (!user) return

		serverErrorMessage = null

		try {
			const result = await createUserLock({
				userId: user.id,
				type
			})

			if (!result.success) {
				const authResult = result as { requiresReauth?: boolean; reauthRoute?: string }

				if (authResult.requiresReauth && authResult.reauthRoute) {
					await gotoReauthRoute(authResult.reauthRoute)
					return
				}

				serverErrorMessage = 'Reauthentication required'
				return
			}
		} catch (e) {
			const err = e as { status?: number; body?: { message?: string } }
			serverErrorMessage = err?.body?.message || 'Failed to set lock status'
		}
	}

	async function onResolveLockRowAction(type: Lock['type']) {
		const user = selectedUserLockState?.user

		if (!user) return

		const activeLock = activeLocks.find((lock) => lock.type === type)

		if (!activeLock) {
			serverErrorMessage = 'No active lock found to resolve'
			return
		}

		serverErrorMessage = null

		try {
			const result = await resolveUserLock({
				lockId: activeLock.id,
				userId: user.id
			})

			if (!result.success) {
				const authResult = result as { requiresReauth?: boolean; reauthRoute?: string }

				if (authResult.requiresReauth && authResult.reauthRoute) {
					await gotoReauthRoute(authResult.reauthRoute)
					return
				}

				serverErrorMessage = 'Reauthentication required'
				return
			}
		} catch (e) {
			const err = e as { status?: number; body?: { message?: string } }
			serverErrorMessage = err?.body?.message || 'Failed to resolve lock status'
		}
	}

	async function onUpdateLockNote(lockId: string, reason: string) {
		const user = selectedUserLockState?.user

		if (!user) return

		serverErrorMessage = null

		try {
			const result = await updateUserLockReason({
				lockId,
				userId: user.id,
				reason
			})

			if (!result.success) {
				const authResult = result as { requiresReauth?: boolean; reauthRoute?: string }

				if (authResult.requiresReauth && authResult.reauthRoute) {
					await gotoReauthRoute(authResult.reauthRoute)
					return
				}

				serverErrorMessage = 'Reauthentication required'
				return
			}
		} catch (e) {
			const err = e as { status?: number; body?: { message?: string } }
			serverErrorMessage = err?.body?.message || 'Failed to update lock note'
		}
	}
</script>

<!-- Container inside the layout -->
<div class="z-10 flex h-full w-full max-w-116 flex-col px-2">
	<div
		aria-hidden="true"
		class={createClass(
			'w-full transition-[max-height,flex-grow] duration-500 ease-[cubic-bezier(0.22,1,0.36,1)]',
			hasSelectedIdentifier ? 'max-h-0 min-h-14 grow-0' : 'max-h-[25dvh] min-h-14 grow'
		)}
	></div>

	<div class="relative flex min-h-40 w-full shrink-0 flex-col items-start pb-6">
		<h1 class="text-2xl font-semibold tracking-tight text-neutral-900">User Lockout</h1>
		<p class="text-neutral-600">Manage user bans and lock status</p>

		<div
			class={createClass(
				'group relative z-10 mt-6 flex h-12 w-full items-center overflow-hidden rounded-2xl focus-within:outline-2 focus-within:outline-blue-500',
				hasSelectedIdentifier ? 'bg-neutral-50' : 'bg-neutral-100'
			)}
		>
			{#if !hasSelectedIdentifier}
				<form
					bind:this={lookupFormElement}
					class="flex h-full w-full items-center"
					autocomplete="off"
					data-1p-ignore="true"
					data-op-ignore="true"
					{...startUserLockLookup.preflight(startUserLockLookupSchema).enhance(async (opts) =>
						startUserLockLookupForm.enhance(opts, {
							onSubmit: () => {
								userLockoutSearchParams.identifier =
									startUserLockLookup.fields.value()?.identifier?.trim() ?? ''
								serverErrorMessage = null
							},
							onReturn: ({ result }) => {
								selectedUserLockState = result
								userLockoutSearchParams.identifier = result.user.identifier
							},
							onIssues: () => {
								serverErrorMessage = 'Please enter a valid email address'
							},
							onError: ({ error }) => {
								const err = error as { body?: { message?: string } }
								serverErrorMessage = err?.body?.message || 'Failed to lookup user'
							}
						})
					)}
				>
					<input
						{...startUserLockLookup.fields.identifier.as('text')}
						{...startUserLockLookupValid.fields('identifier')}
						placeholder="user@email.com"
						inputmode="email"
						autocomplete="off"
						autocapitalize="none"
						autocorrect="off"
						spellcheck="false"
						data-1p-ignore="true"
						data-op-ignore="true"
						oninput={() => (serverErrorMessage = null)}
						class="h-full w-full grow pl-4 font-[450] text-zinc-900 transition-all outline-none selection:bg-sky-200 selection:text-blue-600 placeholder:font-[450] placeholder:text-neutral-400"
					/>

					<div class="flex h-full shrink-0 items-center justify-end pr-2">
						<button type="submit" class="group" disabled={!canContinue}>
							<IconArrowRight
								stroke={3}
								size={26}
								class={createClass(
									'pointer-events-none transition-colors duration-300 group-disabled:text-neutral-500',
									canContinue ? 'text-blue-vibrant' : 'text-neutral-400'
								)}
							/>
						</button>
					</div>
				</form>
			{:else}
				<div class="relative flex h-full w-full items-center justify-center">
					<button
						type="button"
						onclick={resetIdentifier}
						class="absolute left-0 z-10 flex h-full items-center px-3"
						aria-label="Enter a new email"
					>
						<IconChevronLeft class="h-full text-neutral-400 group-hover:text-neutral-700" />
					</button>

					<div
						class="flex h-full w-full items-center justify-center px-11 font-[450] text-neutral-600"
					>
						<Tooltip.Provider delayDuration={260}>
							<Tooltip.Root>
								<Tooltip.Trigger>
									<button
										type="button"
										aria-label="Copy identifier to clipboard"
										onclick={copyIdentifier}
										class="cursor-pointer truncate transition-colors hover:text-neutral-800"
									>
										{selectedUserLockState?.user.identifier}
									</button>
								</Tooltip.Trigger>
								<Tooltip.Content side="top" sideOffset={6} align="center" class="z-20">
									<div
										class="rounded-xl bg-neutral-900 px-3 py-2 text-[0.9rem] font-medium text-neutral-50"
									>
										Click to copy identifier
									</div>
								</Tooltip.Content>
							</Tooltip.Root>
						</Tooltip.Provider>
					</div>
				</div>
			{/if}
		</div>
		{#if serverErrorMessage}
			<p class="mt-2 text-[0.93rem] text-rose-600">{serverErrorMessage}</p>
		{/if}

		<!-- Lock Controls -->
		{#if hasSelectedIdentifier}
			<div class="flex w-full flex-col items-center gap-3 py-9">
				<!-- Bot -->
				<LockRow
					date={botLockRow.date ? getRelativeDate(botLockRow.date) : ''}
					isActive={botLockRow.isActive}
					onAction={() =>
						botLockRow.isActive ? onResolveLockRowAction('bot') : onLockRowAction('bot')}
				>
					{#snippet icon()}
						<Bot color="var(--color-purple-500)" />
					{/snippet}
					{#snippet activeText()}
						Flagged as <strong>bot</strong>
					{/snippet}
					{#snippet inactiveText()}
						Flag as <strong>bot</strong>
					{/snippet}
				</LockRow>
				<!-- Security -->
				<LockRow
					date={securityLockRow.date ? getRelativeDate(securityLockRow.date) : ''}
					isActive={securityLockRow.isActive}
					onAction={() =>
						securityLockRow.isActive
							? onResolveLockRowAction('security')
							: onLockRowAction('security')}
				>
					{#snippet icon()}
						<IconShieldLock class="text-amber-500" />
					{/snippet}
					{#snippet activeText()}
						Locked for <strong>security</strong>
					{/snippet}
					{#snippet inactiveText()}
						Lock for <strong>security</strong>
					{/snippet}
				</LockRow>
				<!-- Ban -->
				<LockRow
					date={banLockRow.date ? getRelativeDate(banLockRow.date) : ''}
					isActive={banLockRow.isActive}
					onAction={() =>
						banLockRow.isActive ? onResolveLockRowAction('ban') : onLockRowAction('ban')}
				>
					{#snippet icon()}
						<IconHandStop class="text-rose-500" />
					{/snippet}
					{#snippet activeText()}
						<strong>Banned</strong> for behavior
					{/snippet}
					{#snippet inactiveText()}
						<strong>Ban</strong> for behavior
					{/snippet}
				</LockRow>
			</div>

			<!-- Timeline -->
			<div class="w-full">
				<div class="h-[1.5px] w-full bg-neutral-200"></div>

				<div class="flex items-baseline justify-between">
					<p class="pt-2 pb-4 text-lg font-medium tracking-tight-md">Timeline</p>
					<p class="text-[0.93rem] text-neutral-600">{lockHistory.length} Events</p>
				</div>

				<div
					class="grid w-full grid-cols-[minmax(0,1fr)_max-content_max-content] items-center gap-x-3"
				>
					{#if lockHistory.length > 0}
						{#each lockHistory as lockEvent (lockEvent.id)}
							<TimelineEntry
								type={getLockTypeLabel(lockEvent.type)}
								createdAt={new Date(lockEvent.lockedAt)}
								resolvedAt={lockEvent.unlockedAt ? new Date(lockEvent.unlockedAt) : undefined}
								note={lockEvent.reason || undefined}
								onSaveNote={(note) => onUpdateLockNote(lockEvent.id, note)}
							/>
						{/each}
					{:else}
						<p class="w-full py-2 text-center text-[0.93rem] text-neutral-600 italic">
							No history of lockouts
						</p>
					{/if}
				</div>
			</div>
		{/if}
	</div>
</div>
