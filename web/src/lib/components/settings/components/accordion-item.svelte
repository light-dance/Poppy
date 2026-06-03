<script lang="ts">
	import type { Snippet } from 'svelte'
	import type { Icon as TablerIcon } from '@tabler/icons-svelte'
	import { Accordion } from 'bits-ui'
	import { createClass } from '@opensky/style'
	import { fade } from 'svelte/transition'
	import { AdaptFit } from '$ui/adapt'
	import { getDialogContext } from '../dialog-context'

	import { IconChevronRight } from '@tabler/icons-svelte'
	import ItemRow from './item-row.svelte'

	type Props = {
		content: Snippet<[{ registerAction: (fn: () => void | Promise<void>) => void }]>
		id: string
		icon: TablerIcon
		title: string
		hint?: string | null
		hintSnippet?: Snippet
		actionButtonText?: string
	}

	let { content, id, icon: Icon, title, hint, hintSnippet, actionButtonText }: Props = $props()

	const { accordionValue } = getDialogContext()
	let isOpen = $derived(accordionValue() === id)

	let actionHandler: (() => void | Promise<void>) | null = $state(null)
	function registerActionHandler(fn: () => void | Promise<void>) {
		actionHandler = fn
	}

	const handleActionClick = async (e: Event) => {
		e.stopPropagation()
		if (actionHandler) {
			await actionHandler?.()
		} else {
			console.warn(
				`AccordionItem for ${title}'s action item was called without any action having been registered so no action was taken`
			)
		}
	}
</script>

<Accordion.Item
	value={id}
	class={createClass(
		'w-full rounded-2xl px-3 transition-all duration-200',
		isOpen
			? 'bg-[#212121] py-3.5 shadow-[inset_0_1px_1.5px_rgba(255,255,255,0.09),inset_0_-1px_4px_rgba(255,255,255,0.03)]'
			: 'py-2 hover:bg-neutral-800/80'
	)}
>
	<AdaptFit class="w-full" innerClass="w-full" direction="y">
		<Accordion.Header>
			<Accordion.Trigger class="flex w-full flex-col gap-3">
				<!-- Row item -->
				<div class="flex h-10 items-center gap-2">
					<ItemRow icon={Icon} {title} showHint={!isOpen} {hint} {hintSnippet} />

					<div class="grow"></div>

					<div class="flex grow items-center justify-end gap-3">
						{#if isOpen && actionButtonText}
							<button
								in:fade={{ delay: 50, duration: 150 }}
								out:fade={{ duration: 150 }}
								onclick={handleActionClick}
								class="h-9 rounded-full bg-linear-to-b from-neutral-600 to-neutral-600 px-4 py-1 text-neutral-100 shadow-[inset_0.5px_0.5px_0_rgba(255,255,255,0.2),inset_-0.5px_-0.5px_0_rgba(255,255,255,0.1)] active:scale-95"
							>
								{actionButtonText}
							</button>
						{/if}
						<div class="h-fit w-fit origin-center transition-transform" class:rotate-90={isOpen}>
							<IconChevronRight class="text-neutral-300 hover:text-neutral-100" />
						</div>
					</div>
				</div>

				<!-- Divider line -->
				{#if isOpen}
					<div class="h-px w-full bg-neutral-500/30"></div>
				{/if}
			</Accordion.Trigger>
		</Accordion.Header>
		<Accordion.Content class="pt-3">
			{@render content({ registerAction: registerActionHandler })}
		</Accordion.Content>
	</AdaptFit>
</Accordion.Item>
