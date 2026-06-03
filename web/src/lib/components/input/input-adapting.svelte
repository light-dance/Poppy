<script lang="ts">
	import type { HTMLInputAttributes } from 'svelte/elements'

	interface Props extends HTMLInputAttributes {
		value?: string | number
		placeholder?: string
		placeholderIsMinWidth?: boolean
		minWidth?: string
		maxWidth?: string
		type?: 'text' | 'email' | 'number' | 'tel' | 'url'
	}

	let {
		value = $bindable(''),
		placeholder,
		placeholderIsMinWidth = false,
		minWidth,
		maxWidth,
		type = 'text',
		style,
		...restProps
	}: Props = $props()

	let inputWidth = $state(0)

	let inputRef: HTMLInputElement | undefined = $state()
	let sizerRef: HTMLDivElement | undefined = $state()
	let placeHolderSizerRef: HTMLDivElement | undefined = $state()

	const updateInputWidth = () => {
		if (!sizerRef) return

		const margin = 2
		let newInputWidth = sizerRef.scrollWidth + margin

		if (placeholder && (!value || placeholderIsMinWidth) && placeHolderSizerRef) {
			newInputWidth = Math.max(newInputWidth, placeHolderSizerRef.scrollWidth + margin)
		}

		inputWidth = newInputWidth
	}

	const copyInputStyles = (): void => {
		if (!window.getComputedStyle || !inputRef || !sizerRef) {
			return
		}

		const computedStyles = window.getComputedStyle(inputRef)
		const stylesToCopy: Array<keyof CSSStyleDeclaration> = [
			'fontSize',
			'fontFamily',
			'fontWeight',
			'fontStyle',
			'letterSpacing',
			'textTransform',
			'border'
		]

		for (const style of stylesToCopy) {
			// eslint-disable-next-line @typescript-eslint/no-explicit-any
			;(sizerRef.style as any)[style] = computedStyles[style]
			if (placeHolderSizerRef) {
				// eslint-disable-next-line @typescript-eslint/no-explicit-any
				;(placeHolderSizerRef.style as any)[style] = computedStyles[style]
			}
		}
	}

	// Copy styles once input is mounted
	$effect(() => {
		if (inputRef && sizerRef) {
			copyInputStyles()
		}
	})

	// Update width when value changes
	$effect(() => {
		// Access value to create dependency
		void value
		updateInputWidth()
	})
</script>

<div class="autosize-wrapper">
	<input
		bind:this={inputRef}
		bind:value
		style:width="{inputWidth}px"
		style:min-width={minWidth}
		style:max-width={maxWidth}
		{style}
		{placeholder}
		{type}
		{...restProps}
	/>
	<div bind:this={sizerRef} class="autosize-sizer">
		{value ?? ''}
	</div>
	{#if placeholder}
		<div bind:this={placeHolderSizerRef} class="autosize-sizer">
			{placeholder}
		</div>
	{/if}
</div>

<style>
	.autosize-wrapper {
		display: flex;
	}
	.autosize-wrapper input {
		box-sizing: content-box;
	}
	.autosize-sizer {
		max-width: 100%;
		visibility: hidden;
		position: absolute;
		left: 0;
		top: 0;
		overflow: scroll;
		white-space: pre;
	}
</style>
