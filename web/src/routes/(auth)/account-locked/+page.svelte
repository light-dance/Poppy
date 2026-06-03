<script lang="ts">
	import { handleLogout } from '$ui/auth/logout'
	import { Bot } from '@lucide/svelte'
	import { IconShieldLock, IconHandStop, IconLogout } from '@tabler/icons-svelte'

	let { data } = $props()

	let multipleLocks = $derived(data.userLock?.length > 1)
</script>

<!-- Container inside the layout -->
<div class="z-10 flex h-full w-full max-w-116 items-center justify-center px-2">
	<div class="relative flex min-h-40 w-full shrink-0 grow flex-col items-start">
		<h1 class="text-2xl font-semibold tracking-tight text-neutral-900">Account Locked</h1>
		<p class="text-neutral-600">
			Your account is currently locked for the {multipleLocks ? 'reasons' : 'reason'} below
		</p>

		<div class="mt-14 mb-3 flex items-center">
			<div class="flex h-9 items-center gap-2 rounded-full bg-neutral-950 px-4 pr-3">
				<p class=" font-medium text-white">
					{data?.identifier}
				</p>
				<div class="h-2 w-2 rounded-full bg-rose-500"></div>
			</div>

			<button
				type="button"
				onclick={async () => {
					try {
						await handleLogout()
					} catch {
						console.error('Failed to logout')
					}
				}}
				class="group/logout flex h-9 cursor-pointer items-center gap-1 px-2 pr-3"
			>
				<IconLogout
					size={22}
					class="text-neutral-600 transition-colors group-hover/logout:text-blue-600"
				/>
				<p
					class="-translate-x-1 font-medium text-neutral-600 opacity-0 blur-[5px] transition-all duration-300 group-hover/logout:translate-x-0 group-hover/logout:text-blue-600 group-hover/logout:opacity-100 group-hover/logout:blur-none"
				>
					Logout
				</p>
			</button>
		</div>

		<div class="flex flex-col gap-3">
			{#if data.userLock?.includes('bot')}
				<div
					class="flex h-9 w-fit items-center gap-2 rounded-full border-[1.5px] border-dashed border-neutral-400/70 px-3"
				>
					<Bot color="var(--color-purple-500)" />
					<p class="text-neutral-600">
						Flagged for <span class="font-semibold text-black">bot</span> activity
					</p>
				</div>
			{/if}

			{#if data.userLock?.includes('security')}
				<div
					class="flex h-9 w-fit items-center gap-2 rounded-full border-[1.5px] border-dashed border-neutral-400/70 px-3"
				>
					<IconShieldLock class="text-amber-500" />
					<p class="text-neutral-600">
						Locked for <span class="font-semibold text-black">security</span> concern
					</p>
				</div>
			{/if}

			{#if data.userLock?.includes('ban')}
				<div
					class="flex h-9 w-fit items-center gap-2 rounded-full border-[1.5px] border-dashed border-neutral-400/70 px-3"
				>
					<IconHandStop class="text-rose-500" />
					<p class="text-neutral-600">
						<span class="font-semibold text-black">Banned</span> for behavior
					</p>
				</div>
			{/if}
		</div>

		<div class="px-3 pt-8">
			<p class="font-medium text-blue-600">Appeal</p>
			<p>To unlock your account you may contact support</p>
		</div>
	</div>
</div>
