<script lang="ts">
	import { fly, fade } from 'svelte/transition'
	import { onMount, onDestroy } from 'svelte'
	import { ProgressText } from '$ui/feedback'
	import Button from '$ui/input/button.svelte'
	import { IconArrowRight } from '@tabler/icons-svelte'
	import { Sequence } from '$utils/timing/sequence.svelte'
	import { getUser } from '$remotes/auth/user.remote'

	import ProfilePic from '$lib/components/settings/content/profile/pic.svelte'
	import EditName from '$lib/components/settings/content/profile/name.svelte'
	import AddPasskey from './add-passkey.svelte'

	let getUserPromise = $derived(getUser())

	// Animation state
	let textProgress = $state(0)
	let showCard = $state(false)

	// Create the animation sequence
	const sequence = new Sequence()

	onMount(() => {
		sequence
			.add(100, () => {
				textProgress = 100
			})
			.add(1100, () => {
				showCard = true
			})
			.run()
	})

	onDestroy(() => {
		sequence.destroy()
	})
</script>

<div
	class="relative flex h-full min-h-full w-full flex-col items-center justify-center bg-black px-7 py-5 text-center"
>
	{#if !showCard}
		<div class="absolute inset-0 z-30 flex min-h-full w-full items-center justify-center">
			<div out:fade={{ duration: 300 }}>
				<ProgressText
					value={textProgress}
					dur={1100}
					primaryColor="var(--color-white)"
					backgroundColor="var(--color-neutral-600)"
					class="text-3xl font-semibold"
					onComplete={() => {
						showCard = true
					}}
				>
					Getting things setup
				</ProgressText>
			</div>
		</div>
	{:else}
		<div class="relative flex min-h-full w-full items-center justify-center">
			<div class="flex w-full max-w-md flex-col items-center gap-6">
				<!-- Header text above card -->
				<div class="flex flex-col items-center gap-1" in:fly={{ y: 20, duration: 200, delay: 500 }}>
					<h1 class="text-3xl font-bold text-white">Welcome</h1>
					<p class="text-lg text-neutral-400">Lets get your account setup</p>
				</div>

				<!-- Main card -->
				<div
					class="z-10 w-full rounded-3xl bg-neutral-900 px-8 py-10 text-neutral-100 shadow-[inset_0_1px_1.5px_rgba(255,255,255,0.09),inset_0_-1px_4px_rgba(255,255,255,0.03)]"
					in:fly={{ y: 80, duration: 250, delay: 500 }}
				>
					<div class="flex flex-col items-center gap-8">
						<div class="flex w-full flex-col items-center gap-4">
							<!-- Profile Picture -->
							{#await getUserPromise}
								<div class="flex h-20 w-20 items-center justify-center rounded-full bg-neutral-800">
									<p class="text-sm text-neutral-500">...</p>
								</div>
							{:then user}
								<ProfilePic profilePic={user.profilePic} />
							{/await}

							<!-- Name -->
							<EditName />
						</div>

						<div class="h-1 w-full rounded-full bg-neutral-800"></div>

						<!-- Passkey -->
						<AddPasskey />
					</div>
				</div>

				<!-- Done button -->
				<div in:fly={{ y: 20, duration: 200, delay: 800 }}>
					<Button
						href="/plan"
						style="primary"
						class="bg-white text-neutral-900 hover:bg-neutral-200"
					>
						Done
						<IconArrowRight size={18} class="ml-1" />
					</Button>
				</div>
			</div>
		</div>
	{/if}
</div>
