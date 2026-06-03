<script lang="ts">
	import { ContextMenu } from 'bits-ui'
	import { IconPencil, IconTrash } from '@tabler/icons-svelte'
	import { createClass } from '@opensky/style'

	import PrecisionPicker from './precision-picker.svelte'
	import { wipeVertical } from '$ui/transition'

	type Props = {
		name: string
		cost: string
		quantityType?: string
	}

	let { name, cost, quantityType }: Props = $props()

	let quantity = $state('')
	let inputRef = $state<HTMLInputElement>()
	let isEditing = $state(false)
	let menuOpen = $state(false)

	function handleKeydown(e: KeyboardEvent) {
		if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
			e.preventDefault()

			const currentLabel = inputRef?.closest('label')
			if (!currentLabel) return

			const siblingLabel =
				e.key === 'ArrowDown'
					? currentLabel.nextElementSibling
					: currentLabel.previousElementSibling

			// If there's a sibling in the same section, focus it
			if (siblingLabel) {
				const targetInput = siblingLabel.querySelector('input')
				targetInput?.focus()
				return
			}

			// Otherwise, try to move to adjacent section
			const currentSection = currentLabel.closest('[data-section]')
			if (!currentSection) return

			const adjacentSection =
				e.key === 'ArrowDown'
					? currentSection.nextElementSibling
					: currentSection.previousElementSibling

			if (adjacentSection) {
				const labels = adjacentSection.querySelectorAll('label')
				const targetLabel = e.key === 'ArrowDown' ? labels[0] : labels[labels.length - 1]
				const targetInput = targetLabel?.querySelector('input')
				targetInput?.focus()
			}
		}

		if (e.key === 'Tab') {
			const currentLabel = inputRef?.closest('label')
			if (!currentLabel) return

			const currentSection = currentLabel.closest('[data-section]')
			if (!currentSection) return

			const targetSection = e.shiftKey
				? currentSection.previousElementSibling
				: currentSection.nextElementSibling

			if (targetSection) {
				e.preventDefault()
				const firstInput = targetSection.querySelector('label input')
				if (firstInput instanceof HTMLInputElement) {
					firstInput.focus()
				}
			}
		}
	}
</script>

<ContextMenu.Root bind:open={menuOpen}>
	<ContextMenu.Trigger
		class={createClass(
			'group/item relative flex w-full flex-col border-b border-b-neutral-200/70 first:rounded-t-xl last:rounded-b-xl last:border-b-0',
			isEditing &&
				'z-200 rounded-xl border-b-blue-vibrant bg-blue-vibrant outline-2 outline-blue-vibrant'
		)}
	>
		<label
			class={createClass(
				'group/row relative flex h-8.5 w-full cursor-text items-stretch group-first/item:rounded-t-xl group-last/item:rounded-b-xl',
				!menuOpen &&
					'focus-within:z-10 focus-within:rounded-lg focus-within:bg-white focus-within:ring-2 focus-within:ring-neutral-200 focus-within:outline-2 focus-within:outline-offset-2 focus-within:outline-blue-vibrant',
				menuOpen && 'bg-blue-500/20',
				isEditing && 'rounded-xl bg-white'
			)}
		>
			{#if !isEditing}
				<input
					type="text"
					bind:this={inputRef}
					bind:value={quantity}
					onkeydown={handleKeydown}
					disabled={isEditing}
					class={createClass(
						'h-full w-15 bg-white/50 px-1.5 py-1.5 text-right font-mono text-[0.9rem] font-medium outline-none group-first/item:rounded-tl-xl group-last/item:rounded-bl-xl focus:rounded-l-lg focus:bg-blue-500/20 focus:text-blue-vibrant',
						isEditing && 'rounded-l-xl'
					)}
				/>
			{:else}
				<button onclick={() => (isEditing = false)} class="h-full w-15 py-1 pl-1">
					<p
						class="flex h-full items-center justify-center rounded-lg bg-blue-400/20 font-mono text-sm font-semibold text-blue-600 capitalize"
					>
						Done
					</p>
				</button>
			{/if}
			<span class="flex w-full items-center justify-between gap-1.5 px-2">
				<span class="grow text-[0.9rem] tracking-tight">{name}</span>
				{#if quantityType && quantityType !== 'whole_unit'}
					<span
						class="rounded-full bg-neutral-300 px-1.5 text-xs font-medium tracking-tight text-neutral-600"
					>
						{quantityType}
					</span>
				{/if}
				<span class="text-[0.85rem] tabular-nums opacity-60">${cost}</span>
			</span>
		</label>

		<!-- Editing UI -->
		{#if isEditing}
			<div transition:wipeVertical class="flex justify-start px-3 py-2 text-white">
				<PrecisionPicker />
				<p>Unit</p>
			</div>
		{/if}
	</ContextMenu.Trigger>

	<ContextMenu.Content
		alignOffset={3}
		class="relative z-40 w-44 rounded-[1.15rem] bg-black p-1 shadow-lg outline-none"
	>
		<ContextMenu.Item class="outline-none" onSelect={() => (isEditing = true)}>
			<div
				class="flex cursor-pointer gap-2 rounded-[0.9rem] px-2 py-1.5 pr-3 text-white hover:bg-neutral-600/80"
			>
				<IconPencil class="text-neutral-200" />
				<p class="px-1.5 font-medium text-neutral-200">Edit</p>
			</div>
		</ContextMenu.Item>
		<ContextMenu.Item class="outline-none" onSelect={() => {}}>
			<div
				class="flex cursor-pointer gap-2 rounded-[0.9rem] px-2 py-1.5 pr-3 text-rose-500 hover:bg-rose-600/30"
			>
				<IconTrash class="text-rose-500" />
				<p class="px-1.5 font-medium text-rose-500">Remove</p>
			</div>
		</ContextMenu.Item>
	</ContextMenu.Content>
</ContextMenu.Root>
