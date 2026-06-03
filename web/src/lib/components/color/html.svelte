<script lang="ts">
	import { browser } from '$app/environment'
	import { onDestroy } from 'svelte'

	let { color }: { color: string | null | false } = $props()

	const CSS_VAR_NAME = '--html-bg-color'

	$effect(() => {
		if (!browser) return

		if (color) {
			document.documentElement.style.setProperty(CSS_VAR_NAME, color)
		} else {
			document.documentElement.style.removeProperty(CSS_VAR_NAME) // remove when color is falsey
		}
	})

	onDestroy(() => {
		if (!browser) return

		document.documentElement.style.removeProperty(CSS_VAR_NAME) // remove when component unmounts
	})
</script>
