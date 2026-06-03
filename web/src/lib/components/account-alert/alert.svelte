<script lang="ts">
	import type { Snippet } from 'svelte'
	import type { Icon as TablerIcon } from '@tabler/icons-svelte'
	import { IconAlertCircleFilled } from '@tabler/icons-svelte'
	import { createClass } from '@opensky/style'
	import MarqueeText from '$ui/interact/marquee-text.svelte'

	type Props = {
		/** The icon displayed at the start of the alert. Defaults to `IconAlertCircleFilled`. */
		icon?: TablerIcon
		/** The primary alert heading. Defaults to `'Account Limited'`. */
		title?: string
		/** Snippet rendered as secondary text alongside the title. */
		secondary?: Snippet
		/** Snippet rendered at the end of the alert for an action (e.g. a button or link). */
		action?: Snippet
		/** Additional context shown as a marquee on hover. */
		info?: string
	}

	let {
		icon: Icon = IconAlertCircleFilled,
		title = 'Account Limited',
		secondary,
		action,
		info
	}: Props = $props()

	let isHovered = $state(false) // Determines whether more info is shown
</script>

<div class="flex min-h-14 justify-center tracking-tight-md text-neutral-100">
	<div
		class="group flex w-full max-w-2xl items-center py-4"
		role="alert"
		onmouseenter={() => (isHovered = true)}
		onmouseleave={() => (isHovered = false)}
	>
		<Icon class="text-orange-400" />

		<div class="relative flex grow cursor-default items-baseline pr-2 pl-1">
			<!-- Normal content -->
			<div
				class={createClass(
					'flex w-full grow items-baseline justify-between whitespace-nowrap transition-opacity',
					info && 'duration-300 group-hover:opacity-0 group-hover:delay-300'
				)}
			>
				<p class="text-lg font-semibold text-neutral-100">{title}</p>

				{#if secondary}
					<p class="font-medium text-neutral-400">
						{@render secondary?.()}
					</p>
				{/if}
			</div>

			<!-- Marquee on hover -->
			{#if info}
				<div
					class="pointer-events-none absolute inset-0 pl-1 opacity-0 transition-opacity delay-0 duration-300 group-hover:opacity-100 group-hover:delay-300 group-hover:duration-300"
				>
					<MarqueeText
						active={isHovered}
						text={info}
						class="flex h-full items-center"
						textClass="font-medium"
					/>
				</div>
			{/if}
		</div>

		{#if action}
			{@render action?.()}
		{/if}
	</div>
</div>
