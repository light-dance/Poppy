<script lang="ts">
	import { onDestroy } from 'svelte'
	import { Spring } from 'svelte/motion'
	import { Tooltip } from 'bits-ui'
	import { TextareaAutosize } from 'runed'
	import {
		IconCircleCheckFilled,
		IconCircleDashed,
		IconNotes,
		IconArrowBackUp
	} from '@tabler/icons-svelte'

	import { createClass } from '@opensky/style'
	import { formatDate, formatDuration } from '$lib/utils/datetime'
	import { createToastBounce } from '$ui/adapt/bounce-behavior'

	type Props = {
		type: string
		createdAt: Date
		resolvedAt?: Date
		note?: string
		onSaveNote: (note: string) => void | Promise<void>
	}

	let { type, createdAt, resolvedAt, note, onSaveNote }: Props = $props()

	let isNoteOpen = $state(false)
	let noteInputElement = $state<HTMLTextAreaElement>()
	let noteDraft = $state('')
	let hasInitializedDraft = $state(false)
	let isSavingNote = $state(false)

	let initialNote = $derived(note?.trim() ?? '')
	let normalizedDraftNote = $derived(noteDraft.trim())
	let hasNote = $derived(Boolean(initialNote))
	let isNoteDirty = $derived(normalizedDraftNote !== initialNote)
	let isResolved = $derived(Boolean(resolvedAt))

	const createdAtDisplay = $derived(formatDate(createdAt, { weekday: true }))
	const resolvedAtDisplay = $derived(resolvedAt ? formatDate(resolvedAt, { weekday: true }) : null)
	const resolutionDuration = $derived(
		resolvedAt
			? formatDuration(resolvedAt.getTime() - createdAt.getTime(), {
					maxUnit: 'day',
					style: 'full'
				}).short
			: 'Pending'
	)

	const { scaleX, scaleY, triggerBounce, reset } = createToastBounce({
		scaleX: 1.06,
		scaleY: 1.06,
		holdDuration: 175
	})

	const rotate = new Spring(0, { stiffness: 0.25, damping: 0.72 })
	let animationTimeout: ReturnType<typeof setTimeout> | undefined

	// Keep local draft aligned with server state whenever there are no unsaved edits.
	$effect(() => {
		if (!hasInitializedDraft || !isNoteDirty) {
			noteDraft = note ?? ''
			hasInitializedDraft = true
		}
	})

	new TextareaAutosize({
		element: () => noteInputElement,
		input: () => noteDraft,
		maxHeight: 220
	})

	function triggerNoteAnimation() {
		if (animationTimeout) clearTimeout(animationTimeout)

		triggerBounce()
		rotate.set(8)

		animationTimeout = setTimeout(() => {
			rotate.set(0)
			animationTimeout = undefined
		}, 130)
	}

	function toggleNote() {
		triggerNoteAnimation()
		isNoteOpen = !isNoteOpen
	}

	function undoNoteChanges() {
		noteDraft = note ?? ''
	}

	async function saveNoteChanges() {
		if (!isNoteDirty || isSavingNote) return

		isSavingNote = true

		try {
			await onSaveNote(normalizedDraftNote)
			noteDraft = normalizedDraftNote
		} finally {
			isSavingNote = false
		}
	}

	onDestroy(() => {
		if (animationTimeout) clearTimeout(animationTimeout)
		rotate.set(0)
		reset()
	})
</script>

<div class="contents" style="--timeline-icon-col: 1.25rem; --timeline-info-gap: 0.5rem;">
	<Tooltip.Provider delayDuration={280}>
		<div class="flex min-w-0 items-center gap-2 py-1 pr-4">
			<Tooltip.Root>
				<Tooltip.Trigger>
					{#snippet child({ props: tooltipProps })}
						<div {...tooltipProps} class="flex h-5 w-5 shrink-0 items-center justify-center">
							{#if isResolved}
								<IconCircleCheckFilled size={19} class="text-sky-400" />
							{:else}
								<IconCircleDashed size={19} class="text-neutral-600" />
							{/if}
						</div>
					{/snippet}
				</Tooltip.Trigger>
				<Tooltip.Content side="top" sideOffset={6} align="center" class="z-20">
					<div class="rounded-2xl bg-neutral-900 px-3 py-2 text-[0.9rem] text-neutral-50">
						<p class="font-medium whitespace-nowrap">{isResolved ? 'Resolved' : 'Active'}</p>
					</div>
				</Tooltip.Content>
			</Tooltip.Root>

			<p class="truncate">{type}</p>

			<button
				type="button"
				onclick={toggleNote}
				class={createClass(
					'flex items-center transition-colors will-change-transform',
					hasNote
						? 'text-neutral-500 hover:text-neutral-700'
						: 'text-neutral-400/40 hover:text-neutral-500'
				)}
				style:transform="rotate({rotate.current}deg)"
				aria-label="Toggle event note"
				aria-expanded={isNoteOpen}
			>
				<span
					class="flex origin-center will-change-transform"
					style:transform="scaleX({scaleX.current}) scaleY({scaleY.current})"
					style:transform-origin="center"
				>
					<IconNotes size={19} />
				</span>
			</button>
		</div>

		<Tooltip.Root>
			<Tooltip.Trigger>
				{#snippet child({ props: tooltipProps })}
					<div
						{...tooltipProps}
						class="justify-self-start py-1 text-[0.92rem] tracking-tight whitespace-nowrap text-neutral-600"
					>
						<span>{createdAtDisplay.date.relative}</span>
					</div>
				{/snippet}
			</Tooltip.Trigger>
			{@render dateInfoTooltip()}
		</Tooltip.Root>

		<Tooltip.Root>
			<Tooltip.Trigger>
				{#snippet child({ props: tooltipProps })}
					<div
						{...tooltipProps}
						class={createClass(
							'min-w-28 justify-self-end py-1 pl-3 text-right text-[0.92rem] font-medium tracking-tight whitespace-nowrap',
							isResolved ? 'text-black' : 'text-neutral-500'
						)}
					>
						<span>{resolvedAtDisplay ? resolvedAtDisplay.date.relative : 'Unresolved'}</span>
					</div>
				{/snippet}
			</Tooltip.Trigger>
			{@render dateInfoTooltip()}
		</Tooltip.Root>
	</Tooltip.Provider>

	<div
		class={createClass(
			'col-span-3 grid transition-[grid-template-rows,margin] duration-400 ease-[cubic-bezier(0.22,1,0.36,1)]',
			isNoteOpen
				? 'mt-1 mb-3 grid-rows-[1fr] delay-0'
				: 'pointer-events-none mt-0 mb-0 grid-rows-[0fr] delay-150'
		)}
		style="margin-left: calc(var(--timeline-icon-col) + var(--timeline-info-gap));"
		aria-hidden={!isNoteOpen}
	>
		<div class="overflow-hidden">
			<div
				class={createClass(
					'rounded-2xl bg-neutral-100 px-3.5 py-2 tracking-tight whitespace-normal transition-[opacity,filter,transform] duration-300 ease-out will-change-[opacity,filter,transform]',
					isNoteOpen ? 'blur-0 opacity-100 delay-150' : 'opacity-0 blur-[3px] delay-0'
				)}
			>
				<textarea
					bind:this={noteInputElement}
					bind:value={noteDraft}
					placeholder="Add a note"
					maxlength={500}
					rows={1}
					class="w-full resize-none bg-transparent text-[0.96rem] text-neutral-700 outline-none placeholder:text-neutral-600"
				></textarea>

				<div class="flex items-center justify-between pt-1.5">
					<button
						type="button"
						onclick={undoNoteChanges}
						disabled={!isNoteDirty || isSavingNote}
						class="flex gap-1 text-[0.92rem] font-medium text-neutral-500 disabled:text-neutral-400/70"
					>
						<IconArrowBackUp size={19} stroke={2} />
						Undo
					</button>

					<button
						type="button"
						onclick={saveNoteChanges}
						disabled={!isNoteDirty || isSavingNote}
						class="text-[0.92rem] font-semibold text-blue-600 disabled:text-blue-300"
					>
						{isSavingNote ? 'Saving...' : 'Save'}
					</button>
				</div>
			</div>
		</div>
	</div>
</div>

{#snippet dateInfoTooltip()}
	<Tooltip.Content side="top" sideOffset={6} align="center" class="z-20">
		<div class="rounded-2xl bg-neutral-900 px-3 py-2 text-[0.9rem] text-neutral-50">
			<p class="font-medium whitespace-nowrap">
				{createdAtDisplay.date.long} at {createdAtDisplay.time.short}
				<span class="rounded-full bg-neutral-600 px-2 py-0.5 font-semibold"
					>{resolutionDuration}</span
				>
				{resolvedAtDisplay
					? `${resolvedAtDisplay.date.long} at ${resolvedAtDisplay.time.short}`
					: 'Unresolved'}
			</p>
		</div>
	</Tooltip.Content>
{/snippet}
