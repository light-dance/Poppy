<script lang="ts">
	import { createClass } from '@opensky/style'
	import { IconCirclePlusFilled, IconMessageChatbotFilled } from '@tabler/icons-svelte'
	import ControlStrip from './control-strip.svelte'
	import Section from './section.svelte'
	import { getItems } from '$remotes/dayticket.remote'
	import { Dialog } from 'bits-ui'
	import { fade, slide } from 'svelte/transition'

	const sections = await getItems()

	let sidePanelOpen = $state(false)

	const togglePanel = () => {
		sidePanelOpen = !sidePanelOpen
	}

	// Group sections by column, sorted by order within each column
	const columns = [0, 1, 2].map((colIndex) =>
		sections.filter((s) => s.column === colIndex).sort((a, b) => a.order.localeCompare(b.order))
	)
</script>

<!-- Overscroll Top -->
<div class="overscroll-top bg-[#F1F1F3]"></div>

<!-- Overscroll Bottom -->
<div class="overscroll-bottom bg-[#EDEBED]"></div>

<!-- Feedback Divide -->
<div
	class="group fixed right-2 bottom-2 z-50 rounded-full p-1.5 delay-75 hover:bg-sky-500 hover:shadow-sm"
>
	<IconMessageChatbotFilled
		class="-scale-x-100 text-neutral-600 delay-75 group-hover:text-sky-50"
	/>
</div>

<div class="min-h-screen w-full bg-linear-to-b from-[#F1F1F3] to-[#EDEBED]">
	<div
		class={createClass(
			'relative z-10 flex h-full min-h-screen w-full flex-col items-center ',
			'transition-transform duration-300 will-change-transform',
			sidePanelOpen && 'origin-center scale-[0.98]'
		)}
	>
		<h1
			class={createClass('pt-18 pb-8 text-center text-xl text-black transition-all duration-150')}
		>
			Log a new ticket
		</h1>

		<!-- Toolbar Group -->
		<div
			class="sticky top-0 z-200 flex w-full items-center justify-center bg-linear-to-b from-[#F1F1F3] to-transparent pt-2 pb-8"
		>
			<ControlStrip {togglePanel} />
		</div>

		<!-- Main ContentVisibilityAutoStateChangeEvent -->
		<div class="grid w-full max-w-280 grid-cols-3 gap-6 py-10">
			{#each columns as column (column)}
				<div class="group/col flex flex-col gap-6">
					{#each column as section (section.id)}
						<Section
							sectionId={section.id}
							title={section.title}
							icon={section.icon}
							collapsed={section.collapsed}
							items={section.items}
						/>
					{/each}

					<button
						class="flex min-h-12 w-full items-center justify-center gap-2 rounded-xl bg-neutral-600/10 opacity-0 transition-opacity group-hover/col:opacity-100"
					>
						<IconCirclePlusFilled size={20} class="text-neutral-800" />
						<p class="medium">Add Section</p>
					</button>
				</div>
			{/each}
		</div>
	</div>

	<!-- Quick Entry -->
	<div
		class="pointer-events-none fixed bottom-0 left-0 z-200 flex h-fit w-full items-center justify-center pb-2"
	>
		<div
			class="pointer-events-auto relative flex h-fit w-md items-center rounded-[1.15rem] bg-white/50 px-4 py-2.5 shadow-[inset_0_1px_1px_0.5px_rgba(255,255,255,1),0_1px_1.5px_0px_rgba(0,0,0,0.08),0_2px_30px_11px_rgba(0,0,0,0.04),0_8px_35px_rgba(0,0,0,0.25)] backdrop-blur-sm"
		>
			<p class="font-medium tracking-tight-sm">
				Type <span class="rounded-lg bg-gray-300 px-2 py-1 font-semibold">/</span> for quick entry
			</p>
		</div>
	</div>

	<!-- Right Overlay -->
	<Dialog.Root bind:open={sidePanelOpen}>
		<Dialog.Portal>
			<Dialog.Overlay forceMount>
				{#snippet child({ props, open })}
					{#if open}
						<div
							{...props}
							transition:fade={{ duration: 250 }}
							class="absolute inset-0 z-400 h-screen w-full bg-black/20 transition-colors"
						></div>
					{/if}
				{/snippet}
			</Dialog.Overlay>
			<Dialog.Content forceMount class="outline-none">
				{#snippet child({ props, open })}
					{#if open}
						<div class="absolute inset-0 z-500 flex h-screen w-full justify-end">
							<div
								{...props}
								in:slide={{ axis: 'x', duration: 300 }}
								out:slide={{ axis: 'x', duration: 300 }}
								class="min-w-lg bg-white shadow-sm outline-none"
							>
								<p>Test</p>
							</div>
						</div>
					{/if}
				{/snippet}
			</Dialog.Content>
		</Dialog.Portal>
	</Dialog.Root>
</div>
