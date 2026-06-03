<script lang="ts">
	import { createClass } from '@opensky/style'
	import { Tween } from 'svelte/motion'
	import { linear } from 'svelte/easing'
	import { untrack } from 'svelte'
	import { Sequence } from '$utils/timing'

	type MarqueeSpeed = 'slow' | 'normal' | 'fast' | number
	const SPEED_MAP: Record<string, number> = { fast: 120, slow: 60, normal: 80 }

	/**
	 * Configures marquee content, activation, styling, and timing.
	 */
	type Props = {
		/** Text content to render and marquee when overflowing. */
		text: string
		/** Enables marquee playback when `true` (typically driven by hover state). */
		active?: boolean
		/** Classes applied to the marquee viewport container. */
		class?: string
		/** Classes applied to each text copy inside the track. */
		textClass?: string
		/** Text color for marquee copies. */
		textColor?: string
		/** Left edge gradient color (fade into content). */
		leftGradientColor?: string
		/** Right edge gradient color (fade out content). */
		rightGradientColor?: string
		/**
		 * Scroll speed as preset or pixels-per-second value.
		 * Higher numbers move faster.
		 */
		speed?: MarqueeSpeed
		/** Pixel gap between the first and duplicated text copy. */
		gap?: number
		/** Initial idle duration before each scroll begins. */
		startDelayMs?: number
		/** Idle duration after scroll completes before replay. */
		endDelayMs?: number
		/** Minimum scrolling duration for very short strings. */
		minDurationMs?: number
		/** Width of left/right gradient overlays in pixels. */
		gradientWidth?: number
	}

	let {
		text,
		active = false,
		class: classProp,
		textClass,
		textColor = 'var(--color-neutral-300)',
		leftGradientColor = 'var(--color-neutral-950)',
		rightGradientColor = 'var(--color-neutral-950)',
		speed = 'normal',
		gap = 42,
		startDelayMs = 1250,
		endDelayMs = 1500,
		minDurationMs = 1200,
		gradientWidth = 18
	}: Props = $props()

	// Speed of text movement
	let pixelsPerSecond = $derived(
		typeof speed === 'number' ? Math.max(1, speed) : (SPEED_MAP[speed] ?? 80)
	)

	let viewportWidth = $state(0) // Container size
	let textWidth = $state(0) // Rendered text size

	let x = new Tween(0) // Tween for the x translation transform

	let hasOverflow = $derived(textWidth > viewportWidth + 1)
	let shouldMarquee = $derived(active && hasOverflow)
	let isAnimating = $derived(x.current < 0)

	let distance = $derived(textWidth + gap)
	let duration = $derived(Math.max(minDurationMs, Math.round((distance / pixelsPerSecond) * 1000)))

	const seq = new Sequence({ interruptible: true })

	const resetAnimation = () => {
		seq.stop()
		x.set(0, { duration: 0 })
	}

	$effect(() => {
		if (!shouldMarquee) {
			untrack(resetAnimation)
			return
		}

		const sd = startDelayMs
		const dur = duration
		const ed = endDelayMs

		untrack(() => {
			seq.clear()
			seq
				.add(sd, () => x.set(-distance, { duration, easing: linear }))
				.add(dur, () => x.set(0, { duration: 0 }))
				.repeats({ delay: ed })
				.run()
		})

		return resetAnimation
	})
</script>

<div
	bind:clientWidth={viewportWidth}
	class={createClass('relative w-full overflow-hidden whitespace-nowrap', classProp)}
	style:--marquee-text-color={textColor}
	style:--marquee-left-gradient={leftGradientColor}
	style:--marquee-right-gradient={rightGradientColor}
	style:--marquee-gradient-width={`${gradientWidth}px`}
>
	<div
		style:transform="translateX({x.current}px)"
		style:--marquee-gap={`${gap}px`}
		class="flex w-max items-center gap-(--marquee-gap) will-change-transform"
	>
		<span
			bind:offsetWidth={textWidth}
			class={createClass('flex-none whitespace-nowrap text-(--marquee-text-color)', textClass)}
			>{text}</span
		>

		{#if shouldMarquee}
			<span
				aria-hidden="true"
				class={createClass('flex-none whitespace-nowrap text-(--marquee-text-color)', textClass)}
				>{text}</span
			>
		{/if}
	</div>

	{#if hasOverflow}
		<div
			class={createClass(
				'pointer-events-none absolute inset-y-0 left-0 w-(--marquee-gradient-width) bg-[linear-gradient(to_right,var(--marquee-left-gradient),transparent)] transition-opacity duration-200',
				isAnimating ? 'opacity-100' : 'opacity-0'
			)}
		></div>
		<div
			class="pointer-events-none absolute inset-y-0 right-0 w-(--marquee-gradient-width) bg-[linear-gradient(to_left,var(--marquee-right-gradient),transparent)]"
		></div>
	{/if}
</div>
