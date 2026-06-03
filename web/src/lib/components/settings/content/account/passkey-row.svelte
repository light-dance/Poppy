<script lang="ts">
	import { createClass } from '@opensky/style'
	import { DropdownMenu, Tooltip } from 'bits-ui'
	import { scale } from 'svelte/transition'
	import {
		IconDots,
		IconFingerprint,
		IconTrash,
		IconPencil,
		IconX,
		IconArrowRight
	} from '@tabler/icons-svelte'

	import { renamePasskey, deletePasskey } from '$remotes/auth/passkey.remote'
	import { AdaptSwap } from '$ui/adapt'
	import { SuspenseSpinner } from '$ui/feedback'
	import { formatDateDuration } from '$lib/utils/datetime'
	import { Confirmation } from '$lib/utils/confirmation.svelte'

	import { getDialogContext } from '../../dialog-context'

	type Passkey = {
		id: string
		name: string | null
		createdAt: Date
	}

	let { passkey }: { passkey: Passkey } = $props()

	const { requireRecentAuth } = getDialogContext()

	// UI state
	let isRenaming = $state(false)
	let checkingAuth = $state(false)
	let renameValue = $state('')
	let renameInput = $state<HTMLInputElement>()
	let pending = $state(false)
	let error = $state(false)

	async function startRename() {
		checkingAuth = true
		const authed = await requireRecentAuth()
		checkingAuth = false

		if (!authed) return

		renameValue = passkey.name ?? ''
		isRenaming = true
		error = false

		// Focus input after state update
		await new Promise((r) => setTimeout(r, 0))
		renameInput?.focus()
		renameInput?.select()
	}

	async function confirmRename() {
		if (renameValue.length < 2 || renameValue === passkey.name) {
			cancelRename()
			return
		}

		pending = true
		error = false

		try {
			await renamePasskey({ passkeyId: passkey.id, newName: renameValue })
			isRenaming = false
		} catch (e) {
			console.error('Failed to rename passkey', e)
			error = true
		} finally {
			pending = false
		}
	}

	function cancelRename() {
		isRenaming = false
		renameValue = ''
		error = false
	}

	function handleRenameKeydown(e: KeyboardEvent) {
		if (e.key === 'Enter') {
			confirmRename()
		} else if (e.key === 'Escape') {
			cancelRename()
		}
	}

	const deleteConfirmation = new Confirmation({
		onRequest: async () => {
			checkingAuth = true
			try {
				return await requireRecentAuth()
			} finally {
				checkingAuth = false
			}
		},
		onConfirm: async () => {
			try {
				await deletePasskey({ passkeyId: passkey.id })
			} catch (e) {
				console.error('Failed to delete passkey', e)
			}
		}
	})
</script>

{#if isRenaming}
	<div class="flex w-full flex-col px-1 py-1">
		<div
			class="group flex w-full flex-col items-center rounded-3xl bg-neutral-900 px-2 pr-3 shadow-[inset_0.5px_0.5px_0_rgba(255,255,255,0.15),inset_-0.5px_-0.5px_0_rgba(255,255,255,0.15)] focus-within:outline-2 focus-within:outline-blue-vibrant"
		>
			<Tooltip.Provider delayDuration={350}>
				<div class="flex w-full items-center gap-2 py-3">
					<Tooltip.Root>
						<Tooltip.Trigger>
							<button
								onclick={cancelRename}
								disabled={pending}
								class="ml-1 aspect-square rounded-full p-1.5 text-neutral-400 hover:bg-neutral-500 hover:text-neutral-100 active:scale-95"
							>
								<IconX />
							</button>
						</Tooltip.Trigger>
						<Tooltip.Content side="top" sideOffset={5} align="center">
							<div
								class="rounded-2xl bg-black px-3 py-2 text-[0.9rem] font-semibold text-neutral-50"
							>
								Cancel
							</div>
						</Tooltip.Content>
					</Tooltip.Root>

					<input
						type="text"
						bind:this={renameInput}
						bind:value={renameValue}
						onkeydown={handleRenameKeydown}
						maxlength="32"
						placeholder="Rename Passkey"
						class="grow border-none font-medium outline-none"
					/>

					{#if error}
						<p class="pr-1.5 tracking-tight-md whitespace-nowrap text-rose-600">Error, try again</p>
					{/if}

					<Tooltip.Root>
						<Tooltip.Trigger>
							<AdaptSwap bind:isActive={pending}>
								<button
									onclick={confirmRename}
									disabled={renameValue.length < 2}
									class={createClass(
										'rounded-full px-5 py-1.5 text-[1.05rem] transition-all active:scale-[0.97]',
										renameValue.length >= 2
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
						</Tooltip.Trigger>
						<Tooltip.Content side="top" sideOffset={5} align="center">
							<div
								class="rounded-2xl bg-black px-3 py-2 text-[0.9rem] font-semibold text-neutral-50"
							>
								Rename Passkey
							</div>
						</Tooltip.Content>
					</Tooltip.Root>
				</div>
			</Tooltip.Provider>
		</div>
	</div>
{:else}
	<div class="flex items-baseline justify-between rounded-2xl py-2 transition-all">
		<div class="flex w-full items-center">
			<div class="flex w-7 justify-start text-neutral-500">
				<IconFingerprint size={22} />
			</div>

			<p class="grow text-[1.08rem] font-medium whitespace-nowrap">{passkey.name}</p>

			{#if deleteConfirmation.confirmationStep}
				<div class="flex h-fit items-center gap-2 rounded-2xl bg-black px-4 py-1 pr-1">
					<p class="text-[0.95rem] font-medium text-rose-500">Delete this passkey?</p>
					<button
						onclick={() => deleteConfirmation.confirm()}
						disabled={deleteConfirmation.pending}
						class="h-full min-h-8 rounded-xl px-2 text-rose-500 hover:bg-rose-600/30 active:scale-95 disabled:opacity-50"
					>
						<IconTrash size={20} />
					</button>
				</div>
				<button
					onclick={() => deleteConfirmation.cancel()}
					disabled={deleteConfirmation.pending}
					class="ml-1 aspect-square min-h-8 rounded-xl p-1.5 text-neutral-400 hover:bg-neutral-500 hover:text-neutral-100 active:scale-95"
				>
					<IconX size={20} />
				</button>
			{:else}
				<p class="text-[0.95rem] font-[450] whitespace-nowrap text-neutral-300">
					Added {formatDateDuration(passkey.createdAt).short} ago
				</p>

				{#if checkingAuth}
					<div class="ml-1 flex aspect-square items-center justify-center rounded-xl p-1.5">
						<SuspenseSpinner size={20} thickness={10} speed="fast" />
					</div>
				{:else}
					<DropdownMenu.Root>
						<DropdownMenu.Trigger
							class="ml-1 aspect-square rounded-xl p-1.5 text-neutral-400 hover:bg-neutral-500 hover:text-neutral-100 active:scale-95"
						>
							<IconDots size={20} />
						</DropdownMenu.Trigger>

						<DropdownMenu.Content
							class="w-44 rounded-[1.15rem] bg-black p-1 shadow-lg outline-none"
							side="left"
							align="center"
							sideOffset={8}
							collisionPadding={8}
						>
							<DropdownMenu.Item onSelect={startRename} class="outline-none">
								<div
									class="flex cursor-pointer gap-2 rounded-[0.9rem] px-2 py-1.5 pr-3 text-white hover:bg-neutral-600/80"
								>
									<IconPencil class="text-neutral-200" />
									<p class="px-1.5 font-medium text-neutral-200">Rename</p>
								</div>
							</DropdownMenu.Item>
							<DropdownMenu.Item onSelect={() => deleteConfirmation.request()} class="outline-none">
								<div
									class="flex cursor-pointer gap-2 rounded-[0.9rem] px-2 py-1.5 pr-3 text-rose-500 hover:bg-rose-600/50"
								>
									<IconTrash class="text-rose-500" />
									<p class="px-1.5 font-medium text-rose-500">Remove</p>
								</div>
							</DropdownMenu.Item>
						</DropdownMenu.Content>
					</DropdownMenu.Root>
				{/if}
			{/if}
		</div>
	</div>
{/if}
