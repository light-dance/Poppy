<script lang="ts">
	import { Dialog, Accordion } from 'bits-ui'
	import { createClass } from '@opensky/style'
	import { slide } from 'svelte/transition'

	import { startReauth } from '$remotes/auth/authenticate.remote'
	import { setDialogContext } from './dialog-context'
	import Toolbar from './components/toolbar.svelte'
	import Content from './content/index.svelte'
	import ReauthDialog from './content/reauth-dialog.svelte'

	// Reference to scrollable content area
	let scrollRegion = $state<HTMLDivElement | null>(null)

	// Height overrides for nested dialogs (controls dialog sizing)
	let nestedDialogHeight = $state<null | number>(null)
	let reauthDialogHeight = $state<null | number>(null)
	const activeDialogHeight = $derived(reauthDialogHeight ?? nestedDialogHeight)
	const isNestedDialogOpen = $derived(!!activeDialogHeight)

	// Currently expanded accordion section ID
	let accordionValue = $state('')

	// Reauth dialog state
	let showReauthDialog = $state(false)
	let reauthResolve = $state<((success: boolean) => void) | null>(null)

	// Checks if user has recent auth, opens reauth dialog if not
	const requireRecentAuth = async (): Promise<boolean> => {
		const result = await startReauth({
			timezone: Intl.DateTimeFormat().resolvedOptions().timeZone
		}).run()

		if (result.recentAuth) {
			return true
		}

		return new Promise((resolve) => {
			reauthResolve = resolve
			showReauthDialog = true
		})
	}

	// Resolves reauth promise with success
	const handleReauthSuccess = () => {
		showReauthDialog = false
		reauthResolve?.(true)
		reauthResolve = null
	}

	// Resolves reauth promise with cancellation
	const handleReauthCancel = () => {
		showReauthDialog = false
		reauthResolve?.(false)
		reauthResolve = null
	}

	// Resets scroll position (used when opening nested dialogs)
	const scrollToTop = () => {
		if (scrollRegion) {
			scrollRegion.scrollTo({ top: 0, behavior: 'auto' })
		}
	}

	// Sets nested dialog height; pass 0 to clear
	const setNestedDialogHeight = (height: number) => {
		if (height > 0) {
			nestedDialogHeight = Math.ceil(height)
		} else {
			nestedDialogHeight = null
		}
	}

	// Sets reauth dialog height; pass 0 to clear
	const setReauthDialogHeight = (height: number) => {
		if (height > 0) {
			reauthDialogHeight = Math.ceil(height)
		} else {
			reauthDialogHeight = null
		}
	}

	setDialogContext({
		requireRecentAuth,
		accordionValue: () => accordionValue,
		scrollToTop,
		setNestedDialogHeight,
		setReauthDialogHeight
	})
</script>

<Dialog.Content forceMount>
	{#snippet child({ props, open })}
		{#if open}
			<div
				class="absolute inset-0 z-100 flex h-screen w-full justify-center"
				data-sveltekit-preload-data="off"
			>
				<div
					{...props}
					in:slide={{ axis: 'y', delay: 300, duration: 400 }}
					out:slide={{ axis: 'y', duration: 200 }}
					class={createClass(
						'relative flex flex-col overflow-hidden bg-neutral-950 text-neutral-100 shadow-lg transition-all duration-200 ease-out outline-none',
						isNestedDialogOpen ? 'mt-5 rounded-[2.25rem]' : 'mt-0 rounded-t-none rounded-b-4xl',
						isNestedDialogOpen ? 'w-[calc(var(--container-xl)-4rem)]' : 'w-xl',
						isNestedDialogOpen ? 'max-h-none' : 'h-fit max-h-152 min-h-52'
					)}
					style:height={activeDialogHeight ? `${activeDialogHeight}px` : ''}
					style:max-height={activeDialogHeight ? `${activeDialogHeight}px` : ''}
				>
					<div
						bind:this={scrollRegion}
						class={createClass('flex-1 overflow-y-auto', isNestedDialogOpen && 'overflow-hidden')}
					>
						<div class="sticky top-0 z-40 h-fit w-full">
							<Toolbar />
						</div>

						<div class="w-full px-3 pb-8">
							<!-- Main settings content -->
							<Accordion.Root type="single" bind:value={accordionValue}>
								<Content />
							</Accordion.Root>

							<!-- Reauth dialog -->
							<ReauthDialog
								bind:open={showReauthDialog}
								onSuccess={handleReauthSuccess}
								onCancel={handleReauthCancel}
							/>
						</div>
					</div>
				</div>
			</div>
		{/if}
	{/snippet}
</Dialog.Content>
