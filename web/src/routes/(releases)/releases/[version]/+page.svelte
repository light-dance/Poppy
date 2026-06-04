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

	<article class="flex flex-col gap-5">
		<div class="flex flex-col gap-2">
			<p class="text-sm font-medium text-neutral-500">
				{data.release.publishedDate} · Version {data.release.version} · Build {data.release.build}
			</p>
			<h1 class="text-2xl font-semibold tracking-normal text-neutral-950">{data.release.title}</h1>
		</div>

		<div class="border-t border-neutral-200 pt-5">
			<p class="whitespace-pre-line text-[0.92rem]/6 font-medium text-neutral-600">
				{data.release.changelog}
			</p>
		</div>
	</article>
</div>
