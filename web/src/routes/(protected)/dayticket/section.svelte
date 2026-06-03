<script lang="ts">
	import { ContextMenu } from 'bits-ui'
	import {
		IconChevronRight,
		IconPencil,
		IconPlus,
		IconListDetails,
		IconCheck,
		IconArrowBackUp
	} from '@tabler/icons-svelte'
	import IconSelection from './icons.svelte'
	import ItemRow from './item-row.svelte'
	import { createClass } from '@opensky/style'
	import { wipeVertical } from '$ui/transition'
	import { updateSectionCollapsed, updateSectionTitle } from '$remotes/dayticket.remote'

	type Item = {
		id: string
		name: string
		cost: string
		quantityType: string
	}

	type Props = {
		sectionId: string
		title: string
		icon: string | null
		collapsed: boolean | null
		items: Item[]
	}

	let { sectionId, title, icon, collapsed, items }: Props = $props()

	function getInitialCollapsed() {
		return collapsed ?? false
	}

	function getInitialEditedTitle() {
		return title
	}

	let isCollapsed = $state(getInitialCollapsed())
	let isEditingName = $state(false)
	let editedTitle = $state(getInitialEditedTitle())
	let titleInputRef = $state<HTMLInputElement>()

	async function toggleCollapsed() {
		isCollapsed = !isCollapsed
		await updateSectionCollapsed({ sectionId, collapsed: isCollapsed }).run()
	}

	function handleDblClick(e: MouseEvent) {
		// Don't toggle if double-clicking the icon selection
		if ((e.target as HTMLElement).closest('[data-icon-selection]')) return
		toggleCollapsed()
	}

	async function startEditingName() {
		editedTitle = title
		isEditingName = true
		await new Promise((r) => setTimeout(r, 0))
		titleInputRef?.focus()
		titleInputRef?.select()
	}

	async function confirmEditName() {
		if (editedTitle.trim() && editedTitle !== title) {
			await updateSectionTitle({ sectionId, title: editedTitle.trim() }).run()
		}
		isEditingName = false
	}

	function cancelEditName() {
		editedTitle = title
		isEditingName = false
	}

	function handleTitleKeydown(e: KeyboardEvent) {
		if (e.key === 'Enter') {
			confirmEditName()
		} else if (e.key === 'Escape') {
			cancelEditName()
		}
	}
</script>

<div class="flex w-full flex-col" data-section>
	<!-- Section Header Row -->
	<div class="relative z-30">
		<ContextMenu.Root>
			<ContextMenu.Trigger
				class={createClass(
					'group relative z-30 flex w-full items-center transition-[padding] duration-200',
					isEditingName && 'pb-2'
				)}
				ondblclick={handleDblClick}
			>
				<!-- Fixed: Icon -->
				<div class="shrink-0">
					<IconSelection {sectionId} {icon} />
				</div>

				<!-- Flexible: Title + Overlaid Item Count -->
				<div class="relative min-w-0 flex-1">
					<div
						class={createClass(
							'flex items-center rounded-[0.65rem] pr-1',
							isEditingName && 'bg-blue-50 py-0.5 outline-2 outline-blue-500'
						)}
					>
						<input
							type="text"
							bind:this={titleInputRef}
							bind:value={editedTitle}
							onkeydown={handleTitleKeydown}
							disabled={!isEditingName}
							class={createClass(
								'min-w-0 flex-1 truncate bg-transparent text-[1.1rem] font-semibold tracking-tight-md outline-none disabled:cursor-default',
								isEditingName && 'px-1.5'
							)}
						/>

						{#if isEditingName}
							<button
								onclick={cancelEditName}
								class="shrink-0 rounded-md p-0.5 text-neutral-500 hover:bg-neutral-300 active:scale-95"
							>
								<IconArrowBackUp size={20} stroke={2.5} />
							</button>
							<button
								onclick={confirmEditName}
								class="ml-1 shrink-0 rounded-md p-0.5 text-blue-500 hover:bg-blue-500 hover:text-white active:scale-95"
							>
								<IconCheck size={20} stroke={2.5} />
							</button>
						{/if}
					</div>

					<!-- Item count overlay (only when collapsed) -->
					{#if isCollapsed && !isEditingName}
						<div class="pointer-events-none absolute inset-y-0 right-0 flex items-center">
							<p
								class="bg-gradient-to-l from-[#EDEDEC] via-[#EDEDEC] to-transparent py-0.5 pr-1 pl-8 tracking-tight-sm text-neutral-700 select-none"
							>
								{items.length} Items
							</p>
						</div>
					{/if}
				</div>

				<!-- Fixed: Chevron -->
				<button onclick={toggleCollapsed} class="shrink-0 px-1">
					<div class="origin-center transition-transform" class:rotate-90={!isCollapsed}>
						<IconChevronRight size={21} class="text-neutral-500 hover:text-neutral-900" />
					</div>
				</button>
			</ContextMenu.Trigger>

			<ContextMenu.Content
				class="relative z-40 w-44 rounded-[1.15rem] bg-black p-1 shadow-lg outline-none"
			>
				<ContextMenu.Item class="outline-none" onSelect={startEditingName}>
					<div
						class="flex cursor-pointer gap-2 rounded-[0.9rem] px-2 py-1.5 pr-3 text-white hover:bg-neutral-600/80"
					>
						<IconPencil class="text-neutral-200" />
						<p class="px-1.5 font-medium text-neutral-200">Edit Name</p>
					</div>
				</ContextMenu.Item>
				<ContextMenu.Item class="outline-none">
					<div
						class="flex cursor-pointer gap-2 rounded-[0.9rem] px-2 py-1.5 pr-3 text-white hover:bg-neutral-600/80"
					>
						<IconPlus class="text-neutral-200" />
						<p class="px-1.5 font-medium text-neutral-200">Add Item</p>
					</div>
				</ContextMenu.Item>
				<ContextMenu.Item class="outline-none">
					<div
						class="flex cursor-pointer gap-2 rounded-[0.9rem] px-2 py-1.5 pr-3 text-white hover:bg-neutral-600/80"
					>
						<IconListDetails class="text-neutral-200" />
						<p class="px-1.5 font-medium text-neutral-200">Edit Items</p>
					</div>
				</ContextMenu.Item>
			</ContextMenu.Content>
		</ContextMenu.Root>
	</div>

	<!-- Section Contents -->
	{#if !isCollapsed}
		<div
			transition:wipeVertical={{ duration: 250 }}
			class="relative z-10 w-full rounded-xl bg-white/50 shadow-2xs"
		>
			{#each items as item (item.id)}
				<ItemRow name={item.name} cost={item.cost} quantityType={item.quantityType} />
			{/each}
		</div>
	{/if}
</div>
