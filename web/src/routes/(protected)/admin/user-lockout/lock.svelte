<script lang="ts">
	import { onMount, type Snippet } from 'svelte'
	import { createClass } from '@opensky/style'
	import { IconCheck, IconX } from '@tabler/icons-svelte'
	import { Dialog } from 'bits-ui'
	import { fade } from 'svelte/transition'

	import { Confirmation } from '$lib/utils/confirmation.svelte'
	import { AdaptSwap } from '$ui/adapt'

	interface Props {
		/** Whether this lock row is currently active */
		isActive: boolean
		/** Callback run after confirmation */
		onAction: () => void | Promise<void>
		/** Text snippet shown in the active state */
		activeText: Snippet
		/** Text snippet shown in the inactive state */
		inactiveText: Snippet
		/** Leading icon snippet */
		icon: Snippet
		/** Optional date label shown on the left */
		date?: string
	}

	let { icon, activeText, inactiveText, date = '', isActive, onAction }: Props = $props()

	let isSwapActive = $state(false)
	let swapData = $state<'active' | 'inactive' | 'confirm' | null>('inactive')

	onMount(() => {
		isSwapActive = true
	})

	$effect(() => {
		if (confirmation.confirmationStep) {
			swapData = 'confirm'
		} else {
			swapData = isActive ? 'active' : 'inactive'
		}
	})

	const confirmation = new Confirmation({
		onConfirm: async () => {
			await onAction()
		}
	})
</script>

<div class="grid h-11 w-full grid-cols-[1fr_auto_1fr] items-center">
	<!-- Date (to left) -->
	<div class="justify-self-end pr-3">
		{#if date && isActive}
			<p class="max-w-full truncate font-medium whitespace-nowrap text-neutral-600">
				{date}
			</p>
		{/if}
	</div>

	<!-- Lock Button -->
	<div
		class={createClass(
			'flex items-center justify-center gap-2 rounded-full transition-all duration-150',
			swapData === 'confirm' && 'bg-neutral-800 shadow-md',
			swapData === 'inactive' && 'bg-white bg-none outline outline-neutral-300 select-none',
			swapData === 'active' && 'bg-neutral-950 select-none'
		)}
	>
		<AdaptSwap
			bind:isActive={isSwapActive}
			bind:swapData
			class="flex items-center will-change-[width,height,transform]"
			adaptSize={true}
		>
			<div class="text-neutral-500">Loading</div>
			{#snippet swapContent(data)}
				<div transition:fade={{ duration: 150 }}>
					{#if data === 'active'}
						<!-- Lock is active -->
						<div class="flex h-9 w-fit items-center gap-2 px-3">
							{@render icon?.()}
							<p class="text-neutral-300 [&>strong]:font-semibold [&>strong]:text-white">
								{@render activeText?.()}
							</p>
						</div>
					{:else if data === 'inactive'}
						<!-- Lock is not active -->
						<button
							onclick={() => confirmation.request()}
							class="flex h-9 w-fit items-center gap-2 px-3"
						>
							{@render icon?.()}
							<p class="text-neutral-600 [&>strong]:font-semibold [&>strong]:text-black">
								{@render inactiveText?.()}
							</p>
						</button>
					{:else if data === 'confirm'}
						<!-- Confirm change state -->
						<Dialog.Root
							open={confirmation.confirmationStep}
							onOpenChange={(open) => {
								if (!open) confirmation.cancel()
							}}
						>
							<Dialog.Content
								forceMount
								trapFocus={false}
								preventScroll={false}
								class="outline-none"
							>
								{#snippet child({ props, open })}
									{#if open}
										<div {...props} class="flex h-11 w-fit items-center gap-2 p-1.5 outline-none">
											<button
												class="flex aspect-square h-full items-center justify-center rounded-full bg-neutral-600 outline-none"
												onclick={() => confirmation.cancel()}
												disabled={confirmation.pending}
												aria-label="Cancel action"
											>
												<IconX size={19} stroke={2.5} class="text-neutral-400" />
											</button>
											<p class="font-medium tracking-tight text-white">Are you sure?</p>
											<button
												class="flex aspect-square h-full items-center justify-center rounded-full bg-green-700/30 outline-none"
												onclick={() => confirmation.confirm()}
												disabled={confirmation.pending}
												aria-label="Confirm action"
											>
												<IconCheck size={19} stroke={2.5} class="text-green-500" />
											</button>
										</div>
									{/if}
								{/snippet}
							</Dialog.Content>
						</Dialog.Root>
					{/if}
				</div>
			{/snippet}
		</AdaptSwap>
	</div>

	<!-- Resolve button (to right) -->
	<div class="justify-self-start pl-3">
		{#if isActive}
			<button
				onclick={() => confirmation.request()}
				class="h-full w-fit rounded-full font-medium text-blue-600">Resolve</button
			>
		{/if}
	</div>
</div>
