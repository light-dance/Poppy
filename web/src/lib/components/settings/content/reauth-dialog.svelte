<script lang="ts">
	import { fade } from 'svelte/transition'
	import { IconShieldLockFilled, IconArrowLeft } from '@tabler/icons-svelte'
	import { Dialog } from 'bits-ui'
	import { getDialogContext } from '../dialog-context'
	import Reauth from '$ui/auth/reauth.svelte'

	type Props = {
		open: boolean
		onSuccess: () => void
		onCancel: () => void
	}
	let { open = $bindable(), onSuccess, onCancel }: Props = $props()

	const { setReauthDialogHeight, scrollToTop } = getDialogContext()

	let innerHeight = $state<number>(0)

	$effect(() => {
		if (innerHeight && open) {
			setReauthDialogHeight(innerHeight)
		} else {
			setReauthDialogHeight(0)
		}
	})

	function handleSuccess() {
		open = false
		onSuccess()
	}

	function handleCancel() {
		onCancel()
	}

	$effect(() => {
		console.log('reauth effect', { open })

		if (open) {
			console.trace('reauth scrollToTop')
			scrollToTop()
		}
	})
</script>

<Dialog.Root bind:open>
	<Dialog.Content forceMount preventScroll={false} interactOutsideBehavior="ignore">
		{#snippet child({ props, open })}
			{#if open}
				<div
					{...props}
					bind:offsetHeight={innerHeight}
					transition:fade={{ duration: 150 }}
					class="absolute top-0 right-0 left-0 z-50 flex w-full flex-col bg-neutral-950"
				>
					<div class="h-fit w-full overflow-y-auto p-3">
						<div class="flex w-full flex-col justify-center p-3 text-neutral-200">
							<div class="flex w-full flex-col px-5 pt-7 pb-10">
								<!-- Heading -->
								<div class="mb-8 flex flex-col">
									<IconShieldLockFilled size={35} class="mb-2 text-sky-500" />
									<h2 class="text-[1.2rem] font-semibold">Reauth</h2>
									<p class="text-[1.05rem] text-neutral-300">
										This action requires reauthentication
									</p>
								</div>

								<Reauth onSuccess={handleSuccess} onCancel={handleCancel} suppressRedirect={true} />
							</div>

							<!-- Buttons -->
							<div class="flex flex-col gap-2">
								<button
									onclick={onCancel}
									class="group flex items-center justify-center gap-2 rounded-full py-4 text-[1.05rem] font-semibold text-white transition-transform hover:bg-neutral-800/70 active:scale-[0.97]"
								>
									<IconArrowLeft />
									Go Back
								</button>
							</div>
						</div>
					</div>
				</div>
			{/if}
		{/snippet}
	</Dialog.Content>
</Dialog.Root>
