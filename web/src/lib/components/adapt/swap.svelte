<script lang="ts">
	import type { Snippet } from 'svelte'
	import { onMount, onDestroy } from 'svelte'
	import { createClass } from '@opensky/style'
	import { Spring } from 'svelte/motion'
	import { createToastBounce } from './bounce-behavior.js'
	import { SPRING_DEFAULTS } from './spring-config.js'

	interface TriggerOptions<T = unknown> {
		/** Data to pass to the swap content */
		data?: T
		/** Duration in ms before auto-hiding (defaults to durationMs prop) */
		duration?: number
	}

	type TriggerFunction<T = unknown> = (options?: TriggerOptions<T>) => void

	interface Props<T = unknown> {
		/** CSS class for the container */
		class?: string
		/** CSS class for the inner elements */
		innerClass?: string
		/** Default content to show when not active */
		children?: Snippet
		/** Content to show when active - receives swapData as parameter */
		swapContent?: Snippet<[T]>
		/** Data passed to swapContent snippet */
		swapData?: T
		/** Whether the swap is currently active */
		isActive?: boolean
		/** Function to trigger the swap with auto-hide timer */
		trigger?: TriggerFunction<T> | null
		/** Default duration in ms before auto-hiding */
		durationMs?: number
		/** Function to open without auto-hide timer */
		open?: ((data?: T) => void) | null
		/** Function to close immediately */
		close?: (() => void) | null
		/** Whether to show bounce animation when interrupted */
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
		children,
		swapContent,
		swapData = $bindable(),
		isActive = $bindable(false),
		trigger = $bindable(null),
		durationMs = 3000,
		open = $bindable(null),
		close = $bindable(null),
		interruptBounce = false,
		adaptSize = false,
		stiffness = SPRING_DEFAULTS.stiffness,
		damping = SPRING_DEFAULTS.damping
	}: Props = $props()

	// Tracks size of the normal content
	let defaultContentWidth = $state(0)
	let defaultContentHeight = $state(0)

	// Tracks size of the swap active content
	let activeContentWidth = $state(0)
	let activeContentHeight = $state(0)

	// Springs for smooth size transitions
	let containerWidth: Spring<number> | undefined = $state()
	let containerHeight: Spring<number> | undefined = $state()

	// Track initialization for adapt mode
	let initialized = $state(false)

	// Initialize springs on mount when adapt mode is enabled
	onMount(() => {
		if (adaptSize) {
			containerWidth = new Spring(defaultContentWidth, { stiffness, damping })
			containerHeight = new Spring(defaultContentHeight, { stiffness, damping })
		}
	})

	// Set initialized flag once we have content measurements
	$effect(() => {
		if (defaultContentHeight && defaultContentWidth) {
			initialized = true
		}
	})

	// Update spring targets when content changes or active state toggles
	$effect(() => {
		if (!adaptSize || !initialized || !containerWidth || !containerHeight) return

		if (isActive && activeContentWidth > 0 && activeContentHeight > 0) {
			containerWidth.target = activeContentWidth
			containerHeight.target = activeContentHeight
		} else if (!isActive && defaultContentWidth > 0 && defaultContentHeight > 0) {
			containerWidth.target = defaultContentWidth
			containerHeight.target = defaultContentHeight
		}
	})

	// Create bounce behavior
	const { scaleX, scaleY, triggerBounce, reset } = createToastBounce()

	// Timer for auto-hide functionality
	let timer = $state<ReturnType<typeof setTimeout> | null>(null)

	// Trigger function with auto-hide timer
	trigger = ({ data, duration = durationMs }: TriggerOptions = {}) => {
		// Clear any existing timer
		if (timer) {
			clearTimeout(timer)
			timer = null
		}

		// Handle bounce behavior if enabled
		if (interruptBounce && isActive) {
			triggerBounce()
		}

		// Set active state and update data
		isActive = true
		if (data !== undefined) {
			swapData = data
		}

		// Set timer to clear message
		timer = setTimeout(() => {
			isActive = false
			timer = null
			reset()
		}, duration)
	}

	// Open function without auto-hide
	open = (data?: unknown) => {
		if (timer) {
			clearTimeout(timer)
			timer = null
		}
		isActive = true
		if (data !== undefined) {
			swapData = data
		}
	}

	// Close function to immediately hide content
	close = () => {
		if (timer) {
			clearTimeout(timer)
			timer = null
		}
		isActive = false
		swapData = undefined
	}

	// Clean up timer on component destroy
	onDestroy(() => {
		if (timer) clearTimeout(timer)
	})
</script>

{#if adaptSize}
	<div
		class={createClass(classProp, 'relative', initialized ? 'overflow-hidden' : '')}
		style:width={initialized
			? `${containerWidth?.current ?? defaultContentWidth}px`
			: 'fit-content'}
		style:height={initialized
			? `${containerHeight?.current ?? defaultContentHeight}px`
			: 'fit-content'}
		style:transform="scaleX({scaleX.current}) scaleY({scaleY.current})"
	>
		{#if isActive}
			<div
				class={createClass(
					innerClass,
					'h-fit w-fit whitespace-nowrap',
					initialized ? 'absolute top-0 left-0' : 'relative'
				)}
				bind:offsetWidth={activeContentWidth}
				bind:offsetHeight={activeContentHeight}
			>
				{@render swapContent?.(swapData)}
			</div>
		{:else}
			<div
				class={createClass(
					innerClass,
					'h-fit w-fit',
					initialized ? 'absolute top-0 left-0' : 'relative'
				)}
				bind:offsetHeight={defaultContentHeight}
				bind:offsetWidth={defaultContentWidth}
			>
				{@render children?.()}
			</div>
		{/if}
	</div>
{:else}
	<div
		class={createClass(classProp)}
		style:transform="scaleX({scaleX.current}) scaleY({scaleY.current})"
	>
		{#if isActive}
			{@render swapContent?.(swapData)}
		{:else if children}
			{@render children()}
		{/if}
	</div>
{/if}
