<script lang="ts">
	import { IconCreditCardFilled } from '@tabler/icons-svelte'
	import '@fontsource/open-runde/700.css'
</script>

<div class="flex items-center gap-2.5 pt-2 pb-5">
	<div class="flex flex-col">
		<p class="font-runde leading-tight font-bold">
			$24.99 <span class="font-normal text-neutral-300">per month</span>
		</p>
		<p class="text-[0.9rem] leading-tight font-medium tracking-tight-md">
			Renews Next Week <span class="font-normal text-neutral-300">- Mar 22</span>
		</p>
	</div>

	<div class="grow"></div>

	<div class="flex items-center gap-2 rounded-full bg-black px-3.5 py-1.5 tracking-tight-md">
		<IconCreditCardFilled class="text-neutral-400" />
		<div class="flex items-center gap-1">
			<div class="flex gap-[0.11rem]">
				<div class="h-1 w-1 rounded-full bg-neutral-400"></div>
				<div class="h-1 w-1 rounded-full bg-neutral-400"></div>
				<div class="h-1 w-1 rounded-full bg-neutral-400"></div>
				<div class="h-1 w-1 rounded-full bg-neutral-400"></div>
			</div>
			<p class="font-bold">8152</p>
		</div>
	</div>
</div>
<div class="flex flex-col gap-2 tracking-tight-md">
	<div class="flex items-center gap-1 tracking-tight-md"></div>
</div>
