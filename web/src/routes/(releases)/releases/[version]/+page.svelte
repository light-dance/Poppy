<script lang="ts">
	let { data } = $props()
</script>

<svelte:head>
	<title>{data.release.title} · Poppy Release Notes</title>
</svelte:head>

<div class="mx-auto flex min-h-full max-w-160 flex-col gap-7 bg-neutral-50 px-6 py-8">
	<div class="flex items-center justify-between gap-4">
		<a
			href="/releases/changelog"
			class="text-sm font-medium text-neutral-500 hover:text-neutral-800"
		>
			Changelog
		</a>
		<a href="/download" class="text-sm font-medium text-neutral-500 hover:text-neutral-800">
			Download
		</a>
	</div>

	<article class="flex flex-col gap-3">
		<div class="flex gap-2 items-baseline">
			<h1 class="text-[1.25rem] font-semibold">{data.release.version}</h1>
			<p class="text-[0.93rem] font-medium text-neutral-600">
				Released {data.release.publishedDate}
			</p>
		</div>

		<div class="border-t border-neutral-400/30 pt-5">
			<h1 class="text-xl font-semibold tracking-normal text-neutral-700">{data.release.title}</h1>

			<p class="whitespace-pre-line text-[0.92rem]/6 font-medium text-neutral-600">
				{data.release.changelog}
			</p>
		</div>
	</article>
</div>
