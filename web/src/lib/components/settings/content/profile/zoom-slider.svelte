<script lang="ts">
	import { Slider } from 'bits-ui'

	let { value = $bindable() } = $props()
</script>

<div class="h-fit w-full max-w-36">
	<div class="relative h-9 w-full rounded-full bg-neutral-800 p-2 inset-shadow-sm">
		<Slider.Root
			type="single"
			bind:value
			min={1}
			max={4}
			step={0.01}
			class="relative flex h-full w-full touch-none items-center select-none"
		>
			<span
				class="relative h-full w-full grow cursor-pointer overflow-hidden rounded-full bg-transparent"
			>
				<Slider.Range class="absolute h-full bg-transparent" />
			</span>

			<Slider.Thumb
				class="z-10 aspect-square h-full cursor-pointer rounded-full bg-neutral-200 shadow-lg transition-colors delay-75 outline-none"
				index={0}
			/>
		</Slider.Root>
	</div>
</div>
