<script lang="ts">
	import type { Snippet } from 'svelte'
	import { onMount } from 'svelte'
	import { createClass } from '@opensky/style'
	import { Spring } from 'svelte/motion'
	import { SPRING_DEFAULTS } from './spring-config.js'

	interface Props {
		/** Content to be displayed with adaptive sizing */
		children: Snippet
		/** CSS class for the container */
		class?: string
		/** Spring stiffness for size animations */
		stiffness?: number
		/** Spring damping for size animations */
		damping?: number
		/** Direction for container to adapt */
		direction?: 'x' | 'y' | 'both'
		/** CSS class for the inner content - use this to override behaviors */
		innerClass?: string
	}

	let {
		children,
		class: classProp,
		stiffness = SPRING_DEFAULTS.stiffness,
		damping = SPRING_DEFAULTS.damping,
		direction = 'both',
		innerClass
	}: Props = $props()

	let applyX = $derived(direction === 'x' || direction === 'both')
	let applyY = $derived(direction === 'y' || direction === 'both')

	// Tracks size of content
	let innerHeight = $state(0)
	let innerWidth = $state(0)

	// Springs for smooth height and width transitions
	let containerHeight: Spring<number> | undefined = $state()
	let containerWidth: Spring<number> | undefined = $state()

	// Initialize springs on mount with current dimensions
	onMount(() => {
		containerHeight = new Spring(innerHeight, { stiffness, damping })
		containerWidth = new Spring(innerWidth, { stiffness, damping })
	})

	// Track whether component has initialized with measurements
	let initialized = $state(false)

	// Set initialized flag once we have content measurements
	$effect(() => {
		if (innerHeight && innerWidth) {
			initialized = true
		}
	})

	// Update spring targets when content dimensions change
	$effect(() => {
		// Skip if dimensions are 0 or no springs created
		if (innerWidth === 0 || innerHeight === 0 || !containerHeight || !containerWidth) return

		// Animate size changes after initial measurement
		containerWidth.target = innerWidth
		containerHeight.target = innerHeight
	})
</script>

<div
	style:height={!applyY
		? 'unset'
		: !initialized
			? 'fit-content'
			: `${containerHeight?.current ?? 0}px`}
	style:width={!applyX
		? 'unset'
		: !initialized
			? 'fit-content'
			: `${containerWidth?.current ?? 0}px`}
	class={createClass(classProp, 'relative', initialized ? 'overflow-hidden' : '')}
>
	<div
		class={createClass(
			initialized ? 'absolute top-0 left-0 h-fit w-fit' : 'relative h-fit w-fit',
			innerClass
		)}
		bind:offsetHeight={innerHeight}
		bind:offsetWidth={innerWidth}
	>
		{@render children()}
	</div>
</div>
