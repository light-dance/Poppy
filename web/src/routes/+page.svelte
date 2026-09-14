<script lang="ts">
	import { resolve } from '$app/paths'

	import { IconArrowNarrowDown } from '@tabler/icons-svelte'
	import { Color } from '$ui/color'

	// const PAGE_BACKGROUND = '#F7F7F7'
	// const HERO_TOP_BACKGROUND = '#E9EBEC'

	const PAGE_BACKGROUND = '#E9EBEC'
	const HERO_TOP_BACKGROUND = '#F7F7F7'
</script>

<Color.HTMLBackground color={PAGE_BACKGROUND} />
<Color.BodyBackground color={PAGE_BACKGROUND} />

<div class="overscroll-top" style:background-color={HERO_TOP_BACKGROUND}></div>

<main
	class="relative isolate flex min-h-screen items-center justify-center overflow-hidden px-6"
	style:background={`linear-gradient(to bottom, ${PAGE_BACKGROUND}, ${HERO_TOP_BACKGROUND})`}
>
	<div class="hero-video-shell" aria-hidden="true">
		<video
			class="hero-video"
			src="/field-video-slowmo-4x-60fps-h264.mp4"
			autoplay
			muted
			playsinline
			preload="auto"
		></video>
	</div>

	<!-- Title Badge -->
	<h1 class="absolute inset-x-0 top-2 z-10 flex flex-col items-center gap-2">
		<span class="title-badge -rotate-2 text-2xl font-medium">Poppy</span>
		<span class="text-lg font-semibold text-black/60">for Mac</span>
	</h1>

	<section class="relative z-10 mx-auto flex max-w-7xl flex-col items-center gap-4 text-center">
		<!-- Download Button -->
		<a
			class="bg-black/50 bg-blend-darken rounded-full pl-4 backdrop-blur-md px-6 py-3 flex items-center justify-center hover:bg-[#007AFF] transition-colors"
			href={resolve('/download')}
		>
			<IconArrowNarrowDown class="text-white" size={26} stroke={3} />
			<p class="text-white opacity-95 bg-blend-lighten text-lg font-semibold">Download</p>
		</a>
	</section>
</main>

<div class="min-h-screen relative">
	<div
		style:--primary={PAGE_BACKGROUND}
		style:--secondary={HERO_TOP_BACKGROUND}
		class="h-28 w-full absolute inset-0 bg-linear-to-t from-(--primary) to-(--secondary)"
	></div>
	<p>TEST</p>
</div>

<style>
	/* Blue badge: flat fill with a soft light inner glow around the edge (sampled from reference) */
	.title-badge {
		display: inline-block;
		padding: 0.5rem 1.5rem 0.55rem;
		border-radius: 1.25rem;
		color: white;
		background: #3c84f7;
		box-shadow:
			inset 0 0 6px rgb(255 255 255 / 0.55),
			inset 0 0 16px rgb(255 255 255 / 0.3);
	}

	.hero-video-shell {
		position: absolute;
		inset: 48% auto auto 50%;
		z-index: 0;
		width: min(96vw, 96vh, 64rem);
		aspect-ratio: 1;
		translate: -50% -50%;
		pointer-events: none;
		overflow: visible;
		-webkit-mask-image: var(--hero-video-mask);
		mask-image: var(--hero-video-mask);
		-webkit-mask-mode: alpha;
		mask-mode: alpha;
		-webkit-mask-repeat: no-repeat;
		mask-repeat: no-repeat;
		-webkit-mask-size: 100% 100%;
		mask-size: 100% 100%;
		--hero-video-mask: radial-gradient(
			circle closest-side at center,
			black 0 58%,
			rgb(0 0 0 / 0.82) 68%,
			rgb(0 0 0 / 0.38) 82%,
			rgb(0 0 0 / 0.08) 94%,
			transparent 100%
		);
	}

	.hero-video {
		width: 100%;
		height: 100%;
		object-fit: cover;
		object-position: center;
		scale: 1.22;
	}
</style>
