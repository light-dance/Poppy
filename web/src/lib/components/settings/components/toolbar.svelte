<script lang="ts">
	import { resolve } from '$app/paths'
	import { Dialog } from 'bits-ui'
	import { IconX, IconHelp } from '@tabler/icons-svelte'
</script>

<div
	class="flex w-full items-center justify-between bg-linear-to-b from-neutral-950 from-70% to-neutral-950/0 px-3 py-3 pb-6"
>
	<Dialog.Close class="flex items-center transition-transform outline-none active:scale-95">
		<IconX size={30} stroke={2.5} />
	</Dialog.Close>

	<p class="text-[1.15rem] font-semibold">Settings</p>

	<a href={resolve('/help')} class="flex items-center transition-transform active:scale-95">
		<IconHelp size={30} />
	</a>
</div>
