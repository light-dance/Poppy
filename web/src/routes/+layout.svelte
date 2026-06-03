<script lang="ts">
	import { afterNavigate } from '$app/navigation'

	import '$theme/app.css'
	import '@fontsource-variable/inter/wght.css'
	import favicon from '$lib/assets/favicon.svg'

	import { SeoTags } from '@opensky/seo'
	import { posthog } from '$utils/posthog'

	let { children } = $props()

	afterNavigate(() => {
		posthog.init()
		posthog.pageView()
	})
</script>

<!-- SEO Tags Mount -->
<SeoTags debug={false} />

<!-- Favicon from imports -->
<svelte:head>
	<link rel="icon" href={favicon} />
</svelte:head>

{@render children?.()}
