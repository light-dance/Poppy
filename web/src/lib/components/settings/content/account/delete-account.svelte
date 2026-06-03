<script lang="ts">
	import { goto } from '$app/navigation'
	import { resolve } from '$app/paths'
	import { Dialog } from 'bits-ui'
	import {
		IconTrashFilled,
		IconCircle,
		IconCircleCheckFilled,
		IconAlertTriangleFilled
	} from '@tabler/icons-svelte'
	import DialogHeader from '../../components/dialog-header.svelte'
	import { scale } from 'svelte/transition'
	import { AdaptSwap, AdaptFit } from '$ui/adapt'
	import { SuspenseText } from '$ui/feedback'
	import { deleteUserAccount } from '$remotes/auth/user.remote'

	type Step = {
		heading: string
		description: string
		prominent?: boolean
	}

	const steps = $state<Step[]>([
		{
			heading: 'Your data will be lost',
			description: 'All of your user data will be completely and permanently lost'
		},
		{
			heading: 'Your subscription will be cancelled',
			description:
				'You will immediately lose access to your subsrciption features and you will not be charged again'
		},
		{
			heading: 'Permanently Delete Account?',
			description:
				'Are you sure you want to delete your account? This is permanent and irreversible.',
			prominent: true
		}
	])

	let currentStep = $state(1)
	let currentState = $state<null | 'pending' | 'success' | 'error'>(null)

	const handleProceed = async () => {
		currentStep += 1
		if (currentStep > steps.length) {
			currentState = 'pending'

			try {
				const result = await deleteUserAccount()

				if (result.success) {
					currentState = 'success'
					goto(resolve('/'))
				} else {
					currentStep = steps.length
					currentState = 'error'
				}
			} catch (e) {
				console.error(e)
				currentStep = steps.length
				currentState = 'error'
			}
		}
	}
</script>

<div class="flex w-full flex-col justify-center p-3 text-neutral-200">
	<div class="flex w-full flex-col px-5 pt-7 pb-12">
		<DialogHeader
			title="Delete Account"
			description="Delete your account and data. This action is permanent"
			icon={IconTrashFilled}
			iconClasses="text-rose-600"
		/>

		<AdaptFit direction="y">
			{#if currentState === 'pending'}
				<div class="pt-6 pb-14">
					<SuspenseText
						class="text-lg font-medium"
						backgroundColor="var(--color-neutral-500)"
						primaryColor="var(--color-neutral-100)">Deleting Account...</SuspenseText
					>
				</div>
			{:else}
				<div class="flex flex-col gap-3">
					{#each steps as step, i (step.heading)}
						{#if i < currentStep}
							<div class="flex gap-2" in:scale>
								{#if !step?.prominent}
									<AdaptSwap isActive={currentStep - 1 > i}>
										<div
											out:scale={{ duration: 200, start: 0.5 }}
											class="flex h-7 w-7 shrink-0 items-center justify-center"
										>
											<IconCircle class="shrink-0" />
										</div>

										{#snippet swapContent()}
											<div
												in:scale={{ delay: 225, duration: 200, start: 0.5 }}
												class="flex h-7 w-7 shrink-0 items-center justify-center"
											>
												<IconCircleCheckFilled class="shrink-0" />
											</div>
										{/snippet}
									</AdaptSwap>
								{:else}
									<div class="flex h-7 w-7 shrink-0 items-center justify-center">
										<IconAlertTriangleFilled class="text-rose-600" />
									</div>
								{/if}
								<div>
									<p class="font-medium text-white capitalize">{step.heading}</p>
									<p class="text-neutral-300">
										{step.description}
									</p>
								</div>
							</div>
						{/if}
					{/each}

					{#if currentState === 'error'}
						<p class="text-rose-500">Something went wrong, please try again</p>
					{/if}
				</div>
			{/if}
		</AdaptFit>
	</div>

	{#if currentState !== 'pending'}
		<!-- Buttons -->
		<div class="flex w-full gap-2">
			<Dialog.Close
				class="flex-1 grow rounded-full bg-neutral-500 py-4 text-[1.05rem] font-semibold text-white transition-transform active:scale-[0.97]"
			>
				Cancel
			</Dialog.Close>

			<button
				onclick={handleProceed}
				class="flex-1 grow rounded-full bg-linear-to-b from-rose-600 to-rose-500 py-4 text-[1.05rem] text-white shadow-[inset_0.5px_0.5px_0_rgba(255,255,255,0.4),inset_-0.5px_-0.5px_0_rgba(255,255,255,0.2)] transition-transform active:scale-[0.97]"
			>
				{currentStep >= steps.length ? 'Delete Account' : 'Confirm'}
			</button>
		</div>
	{/if}
</div>
