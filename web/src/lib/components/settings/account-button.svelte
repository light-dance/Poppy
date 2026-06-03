<script lang="ts">
	import { onMount, onDestroy } from 'svelte'
	import { goto } from '$app/navigation'
	import { createClass } from '@opensky/style'
	import { handleLogout } from '$ui/auth/logout'
	import { getUser } from '$remotes/auth/user.remote'

	import type { Icon as TablerIcon } from '@tabler/icons-svelte'
	import { fade } from 'svelte/transition'
	import { DropdownMenu } from 'bits-ui'
	import { createSequence, delay } from '$lib/utils/timing'
	import { IconSettings, IconDots, IconLogout, IconLink } from '@tabler/icons-svelte'
	import { Adapt } from '$ui/adapt'

	let { openSettings }: { openSettings: () => void } = $props()

	// Get user data
	let getUserPromise = $derived(getUser())
	let lazyUser = $derived(await getUserPromise)

	let user = $derived({
		identifier: lazyUser.identifier || 'Error',
		name: lazyUser.name || 'Error'
	})

	// UI state
	let menuOpen = $state(false)
	let swapActive = $state(false)
	let swapData = $state<'initial' | 'welcome' | 'menu' | null>(null)

	// Setup animation sequence
	const sequence = createSequence({ interruptible: true })
		.at(0, () => {
			swapActive = true
			swapData = 'initial'
		})
		.add(2000, () => {
			swapData = 'welcome'
		})
		.add(3000, () => {
			swapActive = false
			swapData = null
		})

	// Determine if welcome animation should play
	const WELCOME_BACK_THRESHOLD_MINS = 45
	function shouldWelcomeBack() {
		const lastSeenAt = localStorage.getItem('lastSeenAt')
		const elapsed = lastSeenAt ? Date.now() - parseInt(lastSeenAt) : Infinity
		// Update last seen at to local storage
		localStorage.setItem('lastSeenAt', Date.now().toString())
		// Return true if it's been more than threshold
		return elapsed > WELCOME_BACK_THRESHOLD_MINS * 60 * 1000 // 45 mins in ms
	}

	// Update state when menu opens/closes
	function onOpenChange(open: boolean) {
		if (open) {
			menuOpen = true
			sequence.stop()
			swapActive = true
			swapData = 'menu'
		} else {
			menuOpen = false
			swapActive = false
			swapData = null
		}
	}

	onMount(async () => {
		await getUser().refresh()

		if (shouldWelcomeBack()) {
			await delay(500) // Allow fly-in transition to complete
			sequence.run()
		}
	})

	onDestroy(() => {
		sequence.stop()
	})
</script>

<DropdownMenu.Root {onOpenChange}>
	<!-- Dropdown trigger adapting content -->
	<DropdownMenu.Trigger class="outline-none">
		<div
			class={createClass(
				'flex items-center justify-center gap-2 rounded-[3rem] bg-neutral-200 transition-all duration-200',
				swapActive && 'bg-neutral-900 shadow-md',
				menuOpen && 'bg-neutral-700'
			)}
		>
			<Adapt.Swap
				bind:isActive={swapActive}
				bind:swapData
				class="flex items-center"
				adaptSize={true}
			>
				<!-- Default state -->
				<div class="px-2">
					<IconDots color="var(--color-neutral-500)" />
				</div>
				<!-- Swap during welcome -->
				{#snippet swapContent(data)}
					<div transition:fade={{ duration: 200 }}>
						{#if data === 'initial'}
							{@render swapMessage('Logged In', user.identifier)}
						{:else if data === 'welcome'}
							{@render swapMessage('Welcome Back', user.name)}
						{:else if data === 'menu'}
							{@render swapMessage(user.name, user.identifier)}
						{/if}

						{#snippet swapMessage(primaryText: string, secondaryText: string)}
							<div class="flex items-center justify-center gap-1 px-4 py-2">
								<h3 class="text-[0.95rem] font-medium text-white">{primaryText}</h3>
								<p class="text-[0.93rem] text-neutral-300">{secondaryText}</p>
							</div>
						{/snippet}
					</div>
				{/snippet}
			</Adapt.Swap>
		</div>
	</DropdownMenu.Trigger>

	<!-- Dropdown open content -->
	<DropdownMenu.Content
		class="w-44 rounded-[1.15rem] bg-neutral-900 p-1 shadow-lg outline-none"
		sideOffset={8}
		collisionPadding={8}
	>
		{@render dropdownMenuItem('Settings', IconSettings, openSettings)}
		{@render dropdownMenuItem('Homepage', IconLink, () => {
			// eslint-disable-next-line svelte/no-navigation-without-resolve
			goto('/?homepage')
		})}
		{@render dropdownMenuItem('Logout', IconLogout, () => {
			try {
				handleLogout()
			} catch {
				console.error('Failed to logout')
			}
		})}
	</DropdownMenu.Content>
</DropdownMenu.Root>

<!-- Snippet for dropdown items -->
{#snippet dropdownMenuItem(title: string, Icon: TablerIcon, onSelect: () => void)}
	<DropdownMenu.Item {onSelect} class="outline-none">
		<div
			class="flex cursor-pointer items-center gap-2 rounded-[0.9rem] px-2 py-1.5 pr-3 text-white hover:bg-neutral-600/80"
		>
			<Icon class="text-neutral-200" />
			<p class="px-1.5 font-medium text-neutral-200">{title}</p>
		</div>
	</DropdownMenu.Item>
{/snippet}
