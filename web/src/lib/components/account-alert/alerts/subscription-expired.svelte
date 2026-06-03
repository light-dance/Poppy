<script lang="ts">
	import Alert from '../alert.svelte'

	let { expiryDate = 'Dec 12th' }: { expiryDate: string } = $props()
</script>

<Alert
	title="Account Limited"
	info={`Your subscription ended on ${expiryDate} and your account is currently limited. Your data is safe and will not be deleted.`}
>
	{#snippet secondary()}
		Subscription ended <span class="text-white">{expiryDate}</span>
	{/snippet}

	{#snippet action()}
		<button class="rounded-full bg-blue-vibrant px-3 py-1 font-medium">Renew Now</button>
	{/snippet}
</Alert>
