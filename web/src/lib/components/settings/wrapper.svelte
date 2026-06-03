<script lang="ts">
	import { fade, fly } from 'svelte/transition'
	import { Dialog } from 'bits-ui'
	import { createClass } from '@opensky/style'
	import AccountButton from '$ui/settings/account-button.svelte'
	import SettingsPane from '$ui/settings/settings.svelte'

	let { children, shown = $bindable() } = $props()

	const openSettings = () => {
		shown = true
	}
</script>

<!-- Overscroll Top -->
<div class={createClass('overscroll-top', shown ? 'bg-neutral-950' : 'bg-transparent')}></div>

<!-- Settings Root and Overlay -->
<Dialog.Root bind:open={shown}>
	<Dialog.Portal>
		<Dialog.Overlay forceMount>
			{#snippet child({ props, open })}
				{#if open}
					<div
						{...props}
						transition:fade={{ duration: 400 }}
						class="absolute inset-0 z-50 h-screen w-full bg-neutral-100/30 transition-colors data-nested-open:bg-neutral-300/50"
					></div>
				{/if}
			{/snippet}
		</Dialog.Overlay>
		<!-- Content -->
		<SettingsPane />
	</Dialog.Portal>
</Dialog.Root>

<!-- Account Button and Settings -->
<div class="pointer-events-none absolute inset-0 z-100 h-screen w-full">
	{#if !shown}
		<div
			class="flex w-full justify-center pt-1.5"
			out:fly={{ y: -100, duration: 200 }}
			in:fly={{ y: -100, duration: 400, delay: 250 }}
		>
			<div class="pointer-events-auto">
				<AccountButton {openSettings} />
			</div>
		</div>
	{/if}
</div>

{@render children?.()}
