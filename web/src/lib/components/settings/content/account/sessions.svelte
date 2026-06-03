<script lang="ts">
	import {
		getUserSessions,
		invalidateSession,
		invalidateAllSessions
	} from '$remotes/auth/session.remote'
	import { handleLogout } from '$ui/auth/logout'
	import { IconX, IconDeviceMobile, IconDeviceDesktop } from '@tabler/icons-svelte'
	import { Tooltip } from 'bits-ui'
	import { UAParser } from 'ua-parser-js'
	import { formatDateDuration } from '$lib/utils/datetime'

	let { registerAction }: { registerAction: (fn: () => void) => void } = $props()

	let getUserSessionsPromise = $derived(getUserSessions())
	let sessions = $derived(await getUserSessionsPromise)

	function parseUserAgent(userAgent: string) {
		const res = UAParser(userAgent)

		return {
			browser: res.browser.name || 'Unkonw',
			platform: res.os.name || 'Unknown',
			deviceType: res.device.type || 'desktop'
		}
	}

	async function resolveLocation(ip: string | null) {
		if (!ip || ip === 'unknown' || ip === '::1') {
			return null
		}

		try {
			const res = await fetch(`https://get.geojs.io/v1/ip/geo/${ip}.json`)

			if (!res.ok) {
				return null
			}

			return await res.json()
		} catch {
			return null
		}
	}

	const removeSession = async (sessionId: string) => {
		try {
			await invalidateSession(sessionId).updates(getUserSessions())
		} catch {
			console.log('failed to remove session')
		}
	}

	const removeAllSessions = async () => {
		try {
			await invalidateAllSessions()
		} catch {
			console.log('failed to remove session')
		}
	}

	// svelte-ignore state_referenced_locally
	registerAction(async () => {
		await removeAllSessions()
	})
</script>

<div class="flex flex-col">
	<Tooltip.Provider delayDuration={350}>
		{#each sessions.allSessions as session (session.id)}
			{@const parsedUserAgent = parseUserAgent(session.userAgent || '')}
			{@const isCurrentSession = session.id === sessions.currentSessionId}
			<div class="flex items-baseline justify-between rounded-2xl py-2 transition-all">
				<div class="flex w-full items-center">
					<div class="flex w-7 justify-start">
						{#if parsedUserAgent.deviceType === 'mobile'}
							<IconDeviceMobile class="text-neutral-500" size={22} />
						{:else}
							<IconDeviceDesktop class="text-neutral-500" size={22} />
						{/if}
					</div>
					<div class="flex grow items-baseline justify-start gap-1">
						<p class="text-[1.08rem] font-medium whitespace-nowrap">{parsedUserAgent.platform}</p>
						<p class="font-medium whitespace-nowrap text-neutral-300">{parsedUserAgent.browser}</p>
						{#await resolveLocation(session.ipAddress) then location}
							{#if location}
								<p class="max-w-48 shrink truncate pl-1 text-neutral-400">
									{location.city}, {location.region}, {location.country_code3}
								</p>
							{:else}
								<p class="max-w-48 shrink truncate pl-1 text-neutral-500 italic">
									Milky Way Galaxy
								</p>
							{/if}
						{/await}
					</div>
					{#if isCurrentSession}
						<p
							class="rounded-xl bg-neutral-700/60 px-2 py-1 text-[0.95rem] font-[450] whitespace-nowrap text-neutral-300"
						>
							Current Device
						</p>
					{:else}
						<p class="text-[0.95rem] font-[450] whitespace-nowrap text-neutral-300">
							Seen {formatDateDuration(session.lastSeenAt).short} ago
						</p>
					{/if}
					<Tooltip.Root>
						<Tooltip.Trigger>
							<button
								onclick={async () => {
									if (!isCurrentSession) {
										removeSession(session.id)
									} else {
										try {
											await handleLogout()
										} catch {
											console.error('Failed to logout')
										}
									}
								}}
								class="ml-1 aspect-square rounded-xl p-1.5 text-neutral-400 hover:bg-neutral-500 hover:text-neutral-100 active:scale-95"
							>
								<IconX stroke={3} size={20} />
							</button>
						</Tooltip.Trigger>
						<Tooltip.Portal>
							<Tooltip.Content side="top" sideOffset={5} align="center" class="z-200">
								<div
									class="rounded-2xl bg-black px-3 py-2 text-[0.9rem] font-semibold text-neutral-50"
								>
									{isCurrentSession ? 'Logout' : 'Remove Device'}
								</div>
							</Tooltip.Content>
						</Tooltip.Portal>
					</Tooltip.Root>
				</div>
			</div>
		{/each}
	</Tooltip.Provider>
</div>
