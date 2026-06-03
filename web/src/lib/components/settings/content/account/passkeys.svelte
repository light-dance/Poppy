<script lang="ts">
	import { getUserPasskeys } from '$remotes/auth/passkey.remote'
	import { IconCirclePlusFilled } from '@tabler/icons-svelte'
	import AddPasskeyMenu from './add-passkey.svelte'
	import PasskeyRow from './passkey-row.svelte'

	let { registerAction }: { registerAction: (fn: () => void) => void } = $props()

	let addPasskeyShown = $state(false)

	const openAddPasskey = () => {
		addPasskeyShown = true
	}
	const dismissAddPasskey = () => {
		addPasskeyShown = false
	}

	// svelte-ignore state_referenced_locally
	registerAction(() => {
		openAddPasskey()
	})
</script>

<div class="flex flex-col pb-3">
	{#if addPasskeyShown}
		<AddPasskeyMenu close={dismissAddPasskey} />
	{/if}

	{#each await getUserPasskeys() as passkey (passkey.id)}
		<PasskeyRow {passkey} />
	{:else}
		<div class="rounded-4xl flex flex-col items-center py-4">
			{#if !addPasskeyShown}
				<p class="font-semibold tracking-tight-sm text-lg">Secure Your Account</p>
				<p class="max-w-80 tracking-tight-sm text-center text-neutral-300">
					Passkeys are a secure and user-friedly alternative to passwords
				</p>

				<button
					onclick={openAddPasskey}
					class="flex mt-5 gap-2 bg-linear-to-b from-sky-500 to-sky-500 w-fit rounded-full items-center py-2 pl-2 pr-4 active:scale-95 transition-transform"
				>
					<IconCirclePlusFilled />
					<p class="text-lg font-medium">Add Passkey</p>
				</button>
			{/if}
		</div>
	{/each}
</div>
