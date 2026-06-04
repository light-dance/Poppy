<script lang="ts">
	import { onMount } from 'svelte'
	import { resolve } from '$app/paths'

	let downloadLink: HTMLAnchorElement | undefined

	onMount(() => {
		downloadLink?.click()
	})
</script>

<div class="mx-auto flex min-h-full max-w-160 flex-col gap-7 bg-neutral-50 px-6 py-8">
	<div class="flex items-center justify-between gap-4">
		<a href={resolve('/')} class="text-sm font-medium text-neutral-500 hover:text-neutral-800">
			Poppy
		</a>
		<a
			href={resolve('/releases/changelog')}
			class="text-sm font-medium text-neutral-500 hover:text-neutral-800"
		>
			Changelog
		</a>
	</div>

	<div class="flex flex-col gap-2">
		<p class="text-sm font-medium text-neutral-500">Download</p>
		<h1 class="text-2xl font-semibold tracking-normal text-neutral-950">Get Poppy for macOS</h1>
	</div>

	<a
		bind:this={downloadLink}
		href={resolve('/download/latest')}
		download="Poppy.dmg"
		class="rounded-[1.2rem] py-3 text-[1.1rem] bg-black text-white font-bold tracking-tight w-fit px-5"
	>
		Download
	</a>
</div>
