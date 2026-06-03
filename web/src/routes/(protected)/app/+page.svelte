<script lang="ts">
	import { resolve } from '$app/paths'

	import { Button } from '$ui/input'
	// let { data } = $props()
</script>

<div class="flex h-screen w-full flex-col items-center p-1">
	<div class="flex h-full w-full flex-col items-center justify-center gap-2">
		<h1 class="text-2xl font-semibold text-neutral-500">Welcome back</h1>

		<Button href={resolve('/dayticket')} style="primary">Dayticket Tool</Button>
	</div>
</div>
