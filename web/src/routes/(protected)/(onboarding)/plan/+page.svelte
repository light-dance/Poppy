<script lang="ts">
	import { TextMorph } from 'torph/svelte'
	import { RadioGroup } from 'bits-ui'
	import Button from '$ui/input/button.svelte'
	import { createClass } from '@opensky/style'
	import '@fontsource/open-runde/700.css'

	let selectedPlan = $state<'monthly' | 'yearly'>('monthly')

	let selectedPlanPriceString = $derived(selectedPlan === 'monthly' ? '29.99' : '25')
</script>

<div
	class="relative flex h-full min-h-full w-full flex-col items-center justify-center bg-black px-7 py-5 text-center"
>
	<div class="relative flex min-h-full w-full items-center justify-center">
		<div class="flex w-full max-w-md flex-col items-center gap-6">
			<!-- Header text above card -->
			<div class="flex flex-col items-center gap-1">
				<h1 class="text-3xl font-bold text-white">Choose a plan</h1>
				<p class="text-lg text-neutral-400">Every feature for your entire team</p>
			</div>

			<!-- Main card -->
			<div
				class="flex w-full flex-col items-center gap-2 rounded-3xl bg-neutral-900 px-8 py-8 text-neutral-100 shadow-[inset_0_1px_1.5px_rgba(255,255,255,0.09),inset_0_-1px_4px_rgba(255,255,255,0.03)]"
			>
				<!-- Options -->
				<RadioGroup.Root
					bind:value={selectedPlan}
					class="plan-control relative flex w-fit justify-center gap-2 rounded-full bg-black p-2"
				>
					<!-- Sliding background indicator -->
					<div
						class="plan-indicator absolute rounded-full bg-neutral-800 shadow-[inset_0.5px_0.5px_0_rgba(255,255,255,0.2),inset_-0.5px_-0.5px_0_rgba(255,255,255,0.1)]"
					></div>

					<RadioGroup.Item value="monthly">
						{#snippet children({ checked })}
							<div
								class={createClass(
									'plan-option relative z-10 flex items-center rounded-full px-5 py-2',
									checked && 'plan-option-active'
								)}
							>
								<p>Monthly</p>
							</div>
						{/snippet}
					</RadioGroup.Item>

					<RadioGroup.Item value="yearly">
						{#snippet children({ checked })}
							<div
								class={createClass(
									'plan-option relative z-10 flex items-center gap-1.5 rounded-full px-4 py-2 pr-2',
									checked && 'plan-option-active'
								)}
							>
								<p>Yearly</p>
								<p class="rounded-xl bg-blue-800/40 px-2 font-semibold text-blue-vibrant-light">
									-15%
								</p>
							</div>
						{/snippet}
					</RadioGroup.Item>
				</RadioGroup.Root>

				<!-- Pricing -->
				<div class="flex flex-col items-center pt-9 pb-3">
					<p class="font-medium tracking-tight-md text-neutral-300">Per month</p>
					<div class="flex items-baseline gap-0.5">
						<p class="font-runde text-3xl font-bold text-neutral-400">$</p>
						<TextMorph
							text={selectedPlanPriceString}
							class="font-runde text-4xl font-bold text-white"
						/>
					</div>

					<p class="mt-5 min-h-7 tracking-tight-md text-neutral-300">
						{#if selectedPlan === 'yearly'}
							Billed as <span class="text-white">$300 per year</span>, saving
							<span class="text-white">$59.88</span>
						{/if}
					</p>
				</div>

				<!-- Call to action -->
				<div class="flex h-fit w-full flex-col items-center pt-10">
					<p class="leading-5 font-medium tracking-tight-md text-neutral-200">
						No payment due today
					</p>
					<p class="leading-5 font-medium tracking-tight-sm text-neutral-400/80">
						1-month free trial
					</p>
					<p
						class="mt-3 rounded-full bg-white px-8 py-3 text-lg leading-5 font-semibold tracking-tight-sm text-black"
					>
						Get Started for $0
					</p>
				</div>
			</div>

			<!-- Done button -->
			<div>
				<Button
					href="/app"
					style="ghost"
					class="bg-transparent text-neutral-300 hover:bg-neutral-800 hover:text-neutral-100"
				>
					Skip
				</Button>
			</div>
		</div>
	</div>
</div>

<style>
	.plan-control {
		anchor-name: --plan-control;
	}

	.plan-option-active {
		anchor-name: --plan-active;
	}

	.plan-indicator {
		position-anchor: --plan-active;
		top: anchor(top);
		right: anchor(right);
		bottom: anchor(bottom);
		left: anchor(left);
		transition: all 0.2s ease-out;
	}
</style>
