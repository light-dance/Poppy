<script lang="ts">
	import { IconChevronRightFilled } from '@tabler/icons-svelte'
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
		<div class="flex flex-col gap-9">
			{#each data.releases as release, index (release.version)}
				<div class="flex flex-col gap-1">
					<!-- Release Title Row -->
					<div class="flex justify-between items-baseline">
						<a href={`/releases/${release.version}`} class="group flex items-center">
							<div class="text-base font-semibold">
								<span
									class="text-black text-[1.1rem] pr-1 group-hover:text-blue-600 transition-colors"
									>{release.version}</span
								>
								<span
									class="text-neutral-500 tracking-tight-sm group-hover:text-blue-500 transition-colors"
									>{release.title}</span
								>
							</div>
							<IconChevronRightFilled
								size={19}
								stroke={5}
								class="text-blue-500 opacity-0 -translate-x-1 blur-sm group-hover:opacity-100 group-hover:translate-x-0 group-hover:blur-none transition-all delay-75"
							/>
						</a>
						<!-- right side timestamp -->
						<p class="text-sm font-medium text-neutral-400">
							Released <span class="text-neutral-600">{release.publishedDate}</span>
						</p>
					</div>

					<p class="whitespace-pre-line text-[0.92rem]/6 font-medium text-neutral-600">
						{release.changelog}
					</p>

					{#if index < data.releases.length - 1}
						<div class="h-px bg-neutral-200/70 mt-4 rounded-full"></div>
					{/if}
				</div>
			{/each}
		</div>
	{:else}
		<p class="border-t border-neutral-200 py-5 text-[0.92rem]/6 font-medium text-neutral-600">
			No releases published yet.
		</p>
	{/if}
</div>
