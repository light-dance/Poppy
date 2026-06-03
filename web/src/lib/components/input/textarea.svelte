<script lang="ts">
	import { TextareaAutosize } from 'runed'
	import { createClass } from '@opensky/style'

	type Props = { class: string; value: string; placeholder?: string; maxHeight?: number }
	let {
		class: classProp,
		value = $bindable(''),
		placeholder = 'Start writing',
		maxHeight = 400
	}: Props = $props()

	let el = $state<HTMLTextAreaElement>(null!)

	// svelte-ignore state_referenced_locally
	new TextareaAutosize({
		element: () => el,
		input: () => value,
		maxHeight: maxHeight
	})
</script>

<textarea
	class={createClass('w-full resize-none', classProp)}
	bind:this={el}
	bind:value
	{placeholder}
></textarea>
