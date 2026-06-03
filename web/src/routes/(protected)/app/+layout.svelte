<script lang="ts">
	import AccountAlertWrapper from '$ui/account-alert/wrapper.svelte'
	import SettingsWrapper from '$ui/settings/wrapper.svelte'

	import { IconSelector } from '@tabler/icons-svelte'

	let { children } = $props()

	let settingsShown = $state(false)
	let accountAlertActive = $state<false | 'service_disrupted' | 'subscription_expired'>(false)
</script>

<AccountAlertWrapper bind:activeAlert={accountAlertActive}>
	<SettingsWrapper bind:shown={settingsShown}>
		<div class="mx-auto flex max-w-3xl justify-between pt-1.5">
			<!-- LEFT -->
			<div>
				<div class="flex items-center">
					<p
						class="cursor-default rounded-lg px-1.5 font-medium tracking-tight-md text-neutral-600 hover:bg-neutral-200"
					>
						Dashboard
					</p>
					<p class="font-medium text-neutral-600">/</p>
					<p
						class="cursor-default rounded-lg px-1.5 font-medium tracking-tight-md hover:bg-neutral-200"
					>
						Analytics
					</p>
					<IconSelector size={19} stroke={2} class="text-neutral-600" />
				</div>
			</div>
			<!-- RIGHT -->
			<div class="flex items-center">
				<div
					class="group flex cursor-pointer items-center gap-1 rounded-full px-2.5 py-1 transition-all duration-300 hover:bg-white"
				>
					<p class="text-neutral-500 transition-colors group-hover:text-neutral-600">
						Pairing in <span
							class="font-semibold text-neutral-800 transition-colors group-hover:text-neutral-900"
							>9</span
						>
					</p>
					<div class="h-2 w-2 rounded-full bg-linear-to-b from-sky-500 to-blue-300"></div>
				</div>
			</div>
		</div>
		{@render children()}
	</SettingsWrapper>
</AccountAlertWrapper>
