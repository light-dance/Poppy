<script lang="ts">
	import type { Snippet } from 'svelte'
	import { onDestroy } from 'svelte'
	import { createClass } from '@opensky/style'
	import { createToastBounce } from './bounce-behavior.js'

	interface TriggerOptions {
		/** Duration in ms before auto-hiding (defaults to durationMs prop) */
		duration?: number
	}

	type TriggerFunction = (options?: TriggerOptions) => void

	interface Props {
		/** CSS class for the container */
		class?: string
		/** Content to show when revealed */
		children?: Snippet
		/** Whether the content is currently visible */
		isActive?: boolean
		/** Function to trigger the reveal with auto-hide timer */
		trigger?: TriggerFunction | null
		/** Default duration in ms before auto-hiding */
		durationMs?: number
		/** Function to open without auto-hide timer */
		open?: (() => void) | null
		/** Function to close immediately */
		close?: (() => void) | null
		/** Whether to show bounce animation when interrupted */
		interruptBounce?: boolean
	}

	let {
		class: classProp,
		children,
		isActive = $bindable(false),
		trigger = $bindable(),
		durationMs = 3000,
		open = $bindable(null),
		close = $bindable(null),
		interruptBounce = true
	}: Props = $props()

	// Create bounce behavior
	const { scaleX, scaleY, triggerBounce, reset } = createToastBounce()

	// Timer for auto-hide functionality
	let timer: ReturnType<typeof setTimeout> | undefined

	// Trigger function with auto-hide timer
	trigger = ({ duration = durationMs }: TriggerOptions = {}) => {
		// Clear any existing timer
		if (timer) {
			clearTimeout(timer)
		}

		// Trigger bounce animation if already visible and enabled
		if (interruptBounce && isActive) {
			triggerBounce()
		}

		// Set active state
		isActive = true

		// Set timer to remove element
		timer = setTimeout(() => {
			isActive = false
			reset()
			timer = undefined
		}, duration)
	}

	// Open function without auto-hide
	open = () => {
		if (timer) {
			clearTimeout(timer)
			timer = undefined
		}
		isActive = true
	}

	// Close function to immediately hide content
	close = () => {
		if (timer) {
			clearTimeout(timer)
			timer = undefined
		}
		isActive = false
		reset()
	}

	// Clean up timer on component destroy
	onDestroy(() => {
		if (timer) clearTimeout(timer)
	})
</script>

{#if isActive}
	<div
		class={createClass(classProp)}
		style:transform="scaleX({scaleX.current}) scaleY({scaleY.current})"
	>
		{@render children?.()}
	</div>
{/if}
