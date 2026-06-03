<script lang="ts">
	import Alert from '../alert.svelte'
</script>

<Alert
	title="Service Disruption"
	info="Some features may be unavailable or slower than usual. Our team is actively working on a fix."
>
	{#snippet secondary()}
		Some features may be temporarily unavailable
	{/snippet}
</Alert>
