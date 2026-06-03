<script lang="ts">
	import { resolve } from '$app/paths'
	let { children } = $props()
</script>

<div class="relative flex h-full w-full shrink-0 flex-col items-center overflow-y-auto bg-white">
	<a
		class="z-50 mx-auto block pt-2 text-center text-base font-medium tracking-tight-md text-black/55 no-underline transition-all duration-300 hover:text-black/85"
		href={resolve('/(protected)/admin')}>Admin Panel</a
	>

	<div class="flex min-h-0 w-full grow justify-center">
		{@render children()}
	</div>
</div>
