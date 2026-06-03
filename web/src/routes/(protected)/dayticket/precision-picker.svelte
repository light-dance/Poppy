<script lang="ts">
	import { RadioGroup } from 'bits-ui'

	let precision = $state<'whole' | 'tens' | 'hundreds'>('whole')
</script>

<RadioGroup.Root bind:value={precision} class="rounded-xl bg-neutral-100/40 p-1 text-black">
	<RadioGroup.Item id="whole" value="whole">
		{#snippet children({ checked })}
			<div class="px-1.5 tracking-tight {checked && 'rounded-lg bg-white shadow-sm'}">1</div>
		{/snippet}
	</RadioGroup.Item>

	<RadioGroup.Item id="tens" value="tens">
		{#snippet children({ checked })}
			<div class="px-1.5 tracking-tight {checked && 'rounded-lg bg-white shadow-sm'}">
				<span class="font-medium">.0</span>
			</div>
		{/snippet}
	</RadioGroup.Item>

	<RadioGroup.Item id="hundreds" value="hundreds">
		{#snippet children({ checked })}
			<div class="px-1.5 tracking-tight {checked && 'rounded-lg bg-white shadow-sm'}">
				<span class="font-medium">.00</span>
			</div>
		{/snippet}
	</RadioGroup.Item>
</RadioGroup.Root>
