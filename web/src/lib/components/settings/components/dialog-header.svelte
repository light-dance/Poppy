<script lang="ts">
	import type { Icon as TablerIcon } from '@tabler/icons-svelte'
	import { createClass } from '@opensky/style'

	type Props = {
		title: string
		description: string
		icon: TablerIcon
		iconClasses?: string
	}

	let { title, description, icon: Icon, iconClasses = '' }: Props = $props()
</script>

<div class="mb-8 flex flex-col">
	<Icon size={35} class={createClass('mb-2', iconClasses)} />
	<h2 class="text-[1.2rem] font-semibold">{title}</h2>
	<p class="text-[1.05rem] text-neutral-300">{description}</p>
</div>
