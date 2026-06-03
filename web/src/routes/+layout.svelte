<script lang="ts">
	import '$theme/app.css'
	import '@fontsource-variable/inter/wght.css'
	import favicon from '$lib/assets/favicon.svg'

	import { SeoTags } from '@opensky/seo'

	let { children } = $props()
</script>

<!-- SEO Tags Mount -->
<SeoTags debug={false} />

<!-- Favicon from imports -->
<svelte:head>
	<link rel="icon" href={favicon} />
</svelte:head>

{@render children?.()}
