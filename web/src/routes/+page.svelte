<script lang="ts">
	import { Color } from '$ui/color'

	const PAGE_BACKGROUND = '#F7F7F7'
	const HERO_TOP_BACKGROUND = '#D4D4D4'
</script>

<Color.HTMLBackground color={PAGE_BACKGROUND} />
<Color.BodyBackground color={PAGE_BACKGROUND} />

<div class="overscroll-top" style:background-color={HERO_TOP_BACKGROUND}></div>

<main
	class="flex min-h-screen items-center justify-center px-6"
	style:background={`linear-gradient(to bottom, ${HERO_TOP_BACKGROUND}, ${PAGE_BACKGROUND} 50%, ${PAGE_BACKGROUND})`}
>
	<section class="mx-auto flex max-w-7xl flex-col items-center gap-8 text-center text-neutral-950">
		<h1 class="text-[clamp(4rem,12vw,11rem)] leading-[0.86] font-bold tracking-tight-md">
			Poppy for Mac
		</h1>

		<p class="max-w-6xl text-[clamp(1.8rem,4.8vw,5rem)] leading-[0.92] font-bold tracking-tight-md text-neutral-700">
			Installing apps on Mac can be a breeze!
		</p>
	</section>
</main>
