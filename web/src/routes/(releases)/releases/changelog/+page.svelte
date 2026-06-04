<script lang="ts">
	let { data } = $props()
</script>

<svelte:head>
	<title>Poppy Changelog</title>
</svelte:head>

<div class="mx-auto flex min-h-full max-w-160 flex-col gap-7 bg-neutral-50 px-6 py-8">
	<div class="flex items-center justify-between gap-4">
		<a href="/" class="text-sm font-medium text-neutral-500 hover:text-neutral-800">Poppy</a>
		<a href="/download" class="text-sm font-medium text-neutral-500 hover:text-neutral-800">
			Download
		</a>
	</div>

	<div class="flex flex-col gap-2">
		<p class="text-sm font-medium text-neutral-500">Releases</p>
		<h1 class="text-2xl font-semibold tracking-normal text-neutral-950">Changelog</h1>
	</div>

	{#if data.releases.length > 0}
		<div class="flex flex-col">
			{#each data.releases as release (release.version)}
				<article class="border-t border-neutral-200 py-5">
					<div class="flex flex-col gap-2">
						<div class="flex flex-col gap-1">
							<a
								href={`/releases/${release.version}`}
								class="text-base font-semibold text-neutral-950 hover:text-neutral-600"
							>
								{release.title}
							</a>
							<p class="text-sm font-medium text-neutral-500">
								{release.publishedDate} · Version {release.version} · Build {release.build}
							</p>
						</div>

						<p class="whitespace-pre-line text-[0.92rem]/6 font-medium text-neutral-600">
							{release.changelog}
						</p>
					</div>
				</article>
			{/each}
		</div>
	{:else}
		<p class="border-t border-neutral-200 py-5 text-[0.92rem]/6 font-medium text-neutral-600">
			No releases have been published yet.
		</p>
	{/if}
</div>
