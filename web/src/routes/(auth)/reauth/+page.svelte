<script lang="ts">
	import { createClass } from '@opensky/style'
	import Reauth from '$ui/auth/reauth.svelte'
</script>

<!-- Gray background gradient -->
<div class="pointer-events-none absolute inset-0 z-0 h-full w-full bg-neutral-400/10"></div>

<!-- Container inside the layout -->
<div class="z-10 flex h-full w-full max-w-116 items-center justify-center px-2">
	<!-- Login card container -->
	<div
		class={createClass(
			'relative flex min-h-40 w-full shrink-0 grow flex-col items-center p-2.5 transition-all duration-200',
			'rounded-[1.8rem] bg-black pt-3 pb-16'
		)}
	>
		<div class="flex h-fit w-full flex-col pb-8">
			<!-- Message-->
			<div class="w-full flex-col items-start justify-center px-5 pt-5">
				<h2
					class="animate-fade-in-scale text-[1.33rem] leading-loose font-[550] tracking-tight-md text-white"
				>
					Reauth
				</h2>
				<p
					class="animate-fade-in-scale text-[1.05rem] leading-4 font-[430] tracking-tight-lg text-neutral-300"
				>
					This action requires reauthentication
				</p>
			</div>
		</div>

		<Reauth autoStart={true} suppressRedirect={false} />
	</div>
</div>
