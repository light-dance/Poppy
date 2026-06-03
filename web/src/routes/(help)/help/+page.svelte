<script lang="ts">
	import { Textarea } from '$ui/input'
	import { createClass } from '@opensky/style'
	import { IconArrowUp } from '@tabler/icons-svelte'

	let textValue = $state('')

	let isSubmitAvailable = $derived(textValue?.length > 2)
</script>

<div class="mx-auto w-full max-w-4xl px-2 pt-28">
	<p
		class="text-center text-[clamp(1.6rem,4.4vw,3.3rem)] font-semibold tracking-tight selection:bg-sky-200 selection:text-blue-600 dark:text-white"
	>
		We're here to help
	</p>

	<div class="flex w-full items-center justify-center gap-2">
		<div class="h-3 w-3 rounded-full bg-green-600"></div>
		<p class="text-green-600">All systems normal</p>
	</div>

	<div class="flex items-center justify-center gap-3 pt-16 pb-4">
		<div class="h-8 w-8 rounded-full bg-linear-to-b from-neutral-500 to-neutral-400"></div>
		<p class="text-neutral-600 dark:text-neutral-400">
			Chatting with <span class="font-medium text-blue-500">Thomas S.</span>
		</p>
	</div>

	<div class="flex w-full items-center justify-center">
		<div
			class="pointer-events-auto flex max-w-xl grow flex-col rounded-4xl bg-[#FAF8FB] px-3 pb-0 shadow-[inset_0_1px_1.5px_rgba(255,255,255,1),0_1px_1.5px_0px_rgba(0,0,0,0.08),0_2px_30px_11px_rgba(0,0,0,0.04)] dark:bg-[#212121] dark:shadow-[inset_0_1px_1.5px_rgba(255,255,255,0.09),inset_0_-1px_4px_rgba(255,255,255,0.03)]"
		>
			<div class="">
				<Textarea
					class="px-3 pt-6 pb-3 text-black placeholder-black/50 outline-none dark:text-white dark:placeholder-white/60"
					bind:value={textValue}
					maxHeight={300}
					placeholder="Start writing..."
				/>

				<div class="relative flex w-full justify-end overflow-hidden rounded-3xl py-3">
					<button
						class={createClass(
							'z-50 flex h-10 w-10 shrink-0 cursor-pointer items-center justify-center rounded-full bg-neutral-500 p-1.5 shadow-md transition-all',
							'active:scale-95',
							isSubmitAvailable
								? 'bg-neutral-800 text-white shadow-md dark:bg-neutral-300 dark:text-neutral-900'
								: 'bg-neutral-300 text-neutral-500 shadow-none dark:bg-neutral-700 dark:text-neutral-500'
						)}
					>
						<IconArrowUp />
					</button>
				</div>
			</div>
		</div>
	</div>
</div>
