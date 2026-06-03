<script lang="ts">
	import type { HTMLInputAttributes } from 'svelte/elements'
	import { createClass } from '@opensky/style'

	interface Props extends Omit<HTMLInputAttributes, 'type' | 'checked' | 'children' | 'class'> {
		checked?: boolean
		class?: string
		label?: string
	}

	let {
		checked = $bindable(false),
		class: classProp,
		disabled = false,
		label = 'Toggle',
		...restProps
	}: Props = $props()
</script>

<label
	class={createClass(
		'inline-flex w-fit cursor-pointer select-none',
		disabled && 'cursor-not-allowed',
		classProp
	)}
>
	<input
		type="checkbox"
		role="switch"
		bind:checked
		{disabled}
		aria-label={label}
		class="peer sr-only"
		{...restProps}
	/>
	<span
		aria-hidden="true"
		class={createClass(
			'inline-flex h-6 w-11 shrink-0 items-center rounded-full p-[3px] transition-[background-color,box-shadow] duration-200 ease-out peer-focus-visible:ring-2 peer-focus-visible:ring-neutral-900 peer-focus-visible:ring-offset-2 peer-disabled:opacity-70',
			checked ? 'bg-green-500' : 'bg-neutral-300'
		)}
	>
		<span
			class={createClass(
				'aspect-square h-full rounded-full bg-white shadow-[0_1px_2px_rgba(15,23,42,0.28)] transition-transform duration-200 ease-out will-change-transform',
				checked ? 'translate-x-5' : 'translate-x-0'
			)}
		></span>
	</span>
</label>
