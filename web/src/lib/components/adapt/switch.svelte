<script lang="ts">
	import { onDestroy } from 'svelte'
	import type { Snippet } from 'svelte'
	import { createClass } from '@opensky/style'
	import { Spring } from 'svelte/motion'
	import { scale } from 'svelte/transition'
	import { SPRING_DEFAULTS } from './spring-config.js'
	import { createToastBounce } from './bounce-behavior.js'

	interface Props<T = unknown> {
		/** CSS class for the container */
		class?: string
		/** CSS class for the inner elements */
		innerClass?: string
		/** Children snippets - use {#snippet state:name} syntax */
		content: Snippet<[{ state: string; previousState: string; data?: unknown }]>
		/** Data passed to the active state snippet */
		swapData?: T
		/** Currently active state name */
		activeState?: string
		/** Function to change states - exposed for external control */
		changeState?: ((stateName: string, data?: unknown) => void) | null
		/** Function to temporarily change state with auto-return */
		trigger?: ((stateName: string, options?: { data?: unknown; duration?: number }) => void) | null
		/** Default duration in ms before auto-returning to previous state */
		durationMs?: number
		/** Transition function for elements entering */
		transitionIn?: typeof scale
		/** Transition function for elements leaving */
		transitionOut?: typeof scale
		/** Configuration object for entering transitions */
		transitionInConfig?: Record<string, unknown>
		/** Configuration object for leaving transitions */
		transitionOutConfig?: Record<string, unknown>
		/** Whether to show bounce animation when setting same state */
		interruptBounce?: boolean
		/** Whether to smoothly adapt container size to content changes */
		adaptSize?: boolean
		/** Spring stiffness for size animations (when adaptSize is true) */
		stiffness?: number
		/** Spring damping for size animations (when adaptSize is true) */
		damping?: number
	}

	let {
		class: classProp,
		innerClass,
		content,
		swapData = $bindable(),
		activeState = $bindable('default'),
		changeState = $bindable(null),
		trigger = $bindable(null),
		durationMs = 3000,
		transitionIn = scale,
		transitionOut = scale,
		transitionInConfig = { duration: 200, delay: 100, start: 0.8 },
		transitionOutConfig = { duration: 100, start: 0.8 },
		interruptBounce = true,
		adaptSize = true,
		stiffness = SPRING_DEFAULTS.stiffness,
		damping = SPRING_DEFAULTS.damping
	}: Props = $props()

	// Track dimensions for each state
	let stateDimensions = $state<Record<string, { width: number; height: number }>>({})

	// Dimensions of the currently active element
	let currentDimensions = $derived(stateDimensions[activeState])

	// Action to measure element dimensions
	function measureState(node: HTMLElement, stateName: string) {
		const measure = () => {
			stateDimensions = {
				...stateDimensions,
				[stateName]: {
					width: node.offsetWidth,
					height: node.offsetHeight
				}
			}
		}

		// Initial measurement after content renders
		requestAnimationFrame(measure)

		// Re-measure on resize
		const observer = new ResizeObserver(measure)
		observer.observe(node)

		return {
			destroy() {
				observer.disconnect()
			}
		}
	}

	// Springs for smooth size transitions
	let containerWidth: Spring<number> | undefined = $state()
	let containerHeight: Spring<number> | undefined = $state()

	// Track initialization for adapt mode
	let initialized = $state(false)

	// Create springs once we have dimensions
	$effect(() => {
		if (
			adaptSize &&
			currentDimensions?.width &&
			currentDimensions?.height &&
			!containerWidth &&
			!containerHeight
		) {
			containerWidth = new Spring(currentDimensions.width, { stiffness, damping })
			containerHeight = new Spring(currentDimensions.height, { stiffness, damping })
			initialized = true
		}
	})

	// Update spring targets based on active state (adapt mode only)
	$effect(() => {
		if (!adaptSize || !initialized || !containerWidth || !containerHeight) return

		if (currentDimensions && currentDimensions.width > 0 && currentDimensions.height > 0) {
			containerWidth.target = currentDimensions.width
			containerHeight.target = currentDimensions.height
		}
	})

	// Track which states are visible
	let visibleStates = $state<Set<string>>(new Set([activeState]))

	// Track state history
	let previousState = $state<string>('default')

	// Create bounce behavior
	const { scaleX, scaleY, triggerBounce, reset } = createToastBounce()

	// Timer for auto-return functionality
	let timer = $state<ReturnType<typeof setTimeout> | null>(null)

	// Method for switching between states
	changeState = (stateName: string, data?: unknown) => {
		// Clear any existing timer
		if (timer) {
			clearTimeout(timer)
			timer = null
		}

		// Trigger bounce if setting same state and enabled
		if (interruptBounce && activeState === stateName) {
			triggerBounce()
			return
		}

		// Track previous state automatically
		previousState = activeState

		// Update data if provided
		if (data !== undefined) {
			swapData = data
		}

		// Update active state
		activeState = stateName

		// Replace visible states with just the new state
		// This will trigger out transition for old states and in transition for new state
		visibleStates = new Set([stateName])
	}

	// Trigger function with auto-return timer
	trigger = (stateName: string, options?: { data?: unknown; duration?: number }) => {
		const { data, duration = durationMs } = options || {}

		// Clear any existing timer
		if (timer) {
			clearTimeout(timer)
			timer = null
		}

		// Store the state to return to
		const returnState = activeState

		// Change to the new state
		if (changeState) {
			changeState(stateName, data)
		}

		// Set timer to return to previous state
		timer = setTimeout(() => {
			if (changeState) {
				changeState(returnState)
			}
			timer = null
			reset()
		}, duration)
	}

	// Clean up timer on component destroy
	onDestroy(() => {
		if (timer) clearTimeout(timer)
	})
</script>

{#if adaptSize}
	<div
		class={createClass(classProp, 'relative', initialized ? 'overflow-hidden' : '')}
		style:width={initialized && containerWidth ? `${containerWidth.current}px` : 'fit-content'}
		style:height={initialized && containerHeight ? `${containerHeight.current}px` : 'fit-content'}
		style:transform="scaleX({scaleX.current}) scaleY({scaleY.current})"
	>
		{#each Array.from(visibleStates) as stateName (stateName)}
			<div
				class={createClass(innerClass, initialized ? 'absolute top-0 left-0' : '', 'h-fit w-fit')}
				use:measureState={stateName}
				in:transitionIn={transitionInConfig}
				out:transitionOut={transitionOutConfig}
			>
				{@render content({ state: stateName, previousState, data: swapData })}
			</div>
		{/each}
	</div>
{:else}
	<div
		class={createClass(classProp)}
		style:transform="scaleX({scaleX.current}) scaleY({scaleY.current})"
	>
		{#each Array.from(visibleStates) as stateName (stateName)}
			<div
				class={createClass(innerClass)}
				in:transitionIn={transitionInConfig}
				out:transitionOut={transitionOutConfig}
			>
				{@render content({ state: stateName, previousState, data: swapData })}
			</div>
		{/each}
	</div>
{/if}
