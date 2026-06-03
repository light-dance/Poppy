<script lang="ts">
	import { createClass } from '@opensky/style'

	let {
		colorTint = 'var(--color-teal-400)',
		isOpen = false
	}: {
		colorTint: string
		isOpen: boolean
	} = $props()
</script>

<div
	style:--main-color={colorTint}
	class="group h-6.5 w-fit min-w-9 rounded-lg border-2 border-(--main-color)/70 bg-(--main-color)/20 p-[3px] transition-colors duration-150 hover:border-(--main-color) hover:bg-(--main-color)/30"
>
	<div class="h-full w-full">
		<div
			style:--main-color={colorTint}
			class={createClass(
				'h-full rounded-sm bg-(--main-color)/70 transition-all duration-150 group-hover:bg-(--main-color)',
				isOpen ? 'w-[60%]' : 'w-[25%]'
			)}
		></div>
	</div>
</div>
