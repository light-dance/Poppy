<script lang="ts">
	import type { Snippet } from 'svelte'
	import { wipeVertical } from '$ui/transition'
	import { createClass } from '@opensky/style'
	import { HTMLBackground } from '$ui/color'

	import ServiceDisruptionAlert from './alerts/service-disruption.svelte'
	import SubscriptionExpiredAlert from './alerts/subscription-expired.svelte'

	type ActiveAlert = 'service_disrupted' | 'subscription_expired' | false

	type Props = {
		children: Snippet
		activeAlert: ActiveAlert
	}

	let { children, activeAlert = $bindable(false) }: Props = $props()

	// TODO: check server for alert conditions

	// Example Usage:
	// activeAlert = 'subscription_expired'
</script>

<!-- HTML Background -->
<HTMLBackground color={activeAlert ? 'var(--color-neutral-950)' : null} />

<div
	class={createClass(
		'relative min-h-screen w-full bg-neutral-50 transition-[padding] duration-300',
		activeAlert && 'bg-neutral-950 px-3 pb-3'
	)}
>
	{#if activeAlert}
		<div in:wipeVertical={{ duration: 600 }}>
			{#if activeAlert === 'service_disrupted'}
				<ServiceDisruptionAlert />
			{:else if activeAlert === 'subscription_expired'}
				<SubscriptionExpiredAlert expiryDate="Feb 10th" />
			{/if}
		</div>
	{/if}

	<div class={createClass('relative bg-neutral-50', activeAlert && 'rounded-3xl')}>
		{@render children?.()}
	</div>
</div>
