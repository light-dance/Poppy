<script lang="ts">
	import type { Snippet } from 'svelte'
	import type { Icon as TablerIcon } from '@tabler/icons-svelte'
	import { fade } from 'svelte/transition'

	type Props = {
		showHint?: boolean
		icon: TablerIcon
		title: string
		hint?: string | null
		hintSnippet?: Snippet
	}

	let { showHint = true, icon: Icon, title, hint, hintSnippet }: Props = $props()
</script>

<!-- Icon -->
<div class="flex w-7 justify-start text-neutral-500">
	<Icon size={24} />
</div>

<!-- Title -->
<h2 class="text-[1.2rem] font-medium tracking-tight text-neutral-50">{title}</h2>

<!-- Hint -->
{#if showHint && (hintSnippet || hint)}
	<div transition:fade={{ duration: 200 }} class="flex text-neutral-400">
		{#if hintSnippet}
			{@render hintSnippet?.()}
		{:else if hint}
			<p>{hint}</p>
		{/if}
	</div>
{/if}
