<script lang="ts">
	import type { Snippet } from 'svelte'
	import type { Icon as TablerIcon } from '@tabler/icons-svelte'
	import { Dialog } from 'bits-ui'
	import { fade } from 'svelte/transition'
	import { IconDotsVertical } from '@tabler/icons-svelte'
	import { SuspenseSpinner } from '$ui/feedback'
	import { getDialogContext } from '../dialog-context'
	import ItemRow from './item-row.svelte'

	type Props = {
		content: Snippet<[{ close: () => void }]>
		icon: TablerIcon
		title: string
		hint?: string | null
		hintSnippet?: Snippet
		protected?: boolean
	}

	let {
		content,
		icon: Icon,
		title,
		hint,
		hintSnippet,
		protected: requiresReauth = false
	}: Props = $props()

	let open = $state(false)
	let checkingAuth = $state(false)
	let innerHeight = $state<number>(0)

	const close = () => {
		open = false
	}

	const { setNestedDialogHeight, scrollToTop, requireRecentAuth } = getDialogContext()

	async function handleTriggerClick() {
		if (requiresReauth) {
			checkingAuth = true
			const authed = await requireRecentAuth()
			checkingAuth = false

			if (!authed) return
		}

		open = true
	}

	$effect(() => {
		if (open) {
			scrollToTop()
		}
	})

	$effect(() => {
		if (innerHeight && open) {
			setNestedDialogHeight(innerHeight)
		} else {
			setNestedDialogHeight(0)
		}
	})
</script>

<Dialog.Root bind:open>
	<button
		onclick={handleTriggerClick}
		class="w-full rounded-2xl px-3 py-2 transition-all duration-200 hover:bg-neutral-800/80"
	>
		<!-- Row item -->
		<div class="flex h-10 items-center gap-2">
			<ItemRow icon={Icon} {title} {hint} {hintSnippet} />

			<div class="grow"></div>

			<div class="flex grow items-center justify-end gap-3">
				<div class="h-fit w-fit origin-center transition-transform">
					{#if checkingAuth}
						<SuspenseSpinner size={20} thickness={10} speed="fast" />
					{:else}
						<IconDotsVertical class="text-neutral-300 hover:text-neutral-100" />
					{/if}
				</div>
			</div>
		</div>
	</button>
	<Dialog.Content forceMount preventScroll={false} interactOutsideBehavior="ignore">
		{#snippet child({ props, open })}
			{#if open}
				<div
					{...props}
					bind:offsetHeight={innerHeight}
					transition:fade={{ duration: 150 }}
					class="absolute top-0 right-0 left-0 z-50 flex w-full flex-col bg-neutral-950"
				>
					<div class="h-fit w-full overflow-y-auto p-3">
						{@render content({ close })}
					</div>
				</div>
			{/if}
		{/snippet}
	</Dialog.Content>
</Dialog.Root>
