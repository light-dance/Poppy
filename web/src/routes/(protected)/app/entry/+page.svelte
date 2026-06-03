<script lang="ts">
	import {
		IconMapPinFilled,
		IconCalendarWeekFilled,
		IconPackage,
		IconClipboardCheckFilled,
		IconPlus,
		IconArrowNarrowRight,
		IconFileCheckFilled,
		IconCircleArrowRightFilled,
		IconStopwatch
	} from '@tabler/icons-svelte'
</script>

<div class="px-2 pt-24 pb-10">
	<div class="flex flex-col gap-3">
		<div
			class="flex w-fit items-center gap-[0.15rem] rounded-full border-[1.5px] border-dashed border-neutral-400/70 px-3 py-2 pl-2.5 tracking-tight-md"
		>
			<IconMapPinFilled size={19} class="text-neutral-600" />
			<div class="flex items-baseline gap-1 tracking-tight-md">
				<p class="text-[1.1rem] font-medium">Redwood Park</p>
				<p class="font-semibold text-blue-500">Lot 12B</p>
				<p class="text-[0.9rem] text-neutral-500">RCI Builders</p>
			</div>
		</div>

		<div
			class="flex w-fit items-center gap-[0.15rem] rounded-full border-[1.5px] border-dashed border-neutral-400/70 px-3 py-2 pl-2.5 tracking-tight-md"
		>
			<IconCalendarWeekFilled size={19} class="text-neutral-600" />
			<div class="flex items-baseline gap-1 tracking-tight-md">
				<p class="text-[1.1rem] font-medium">Today</p>
			</div>
		</div>
	</div>

	<div class="flex items-center pt-8 pb-3">
		<div class="flex h-10 w-10 items-center justify-center rounded-full bg-stone-300">
			<p class="font-bold">TC</p>
		</div>
		<p class="pl-1.5 font-medium tracking-tight text-neutral-600">Just You</p>
		<div class="grow"></div>
		<button
			class="flex h-10 items-center justify-center gap-1 rounded-full bg-sky-100 px-3 text-sky-600"
		>
			<IconPlus size={19} stroke={3} />
			<p class="font-medium">Add Crew</p>
		</button>
	</div>

	<div class="overflow-hidden rounded-3xl bg-neutral-200/70 py-3">
		<div class="flex items-baseline gap-2 overflow-x-scroll px-3">
			<div class="flex items-center gap-1 rounded-3xl bg-white px-4.5 py-1.5">
				<div class="flex items-baseline">
					<p class="text-[1.25rem] font-semibold text-neutral-800 tabular-nums">8:45</p>
					<p class="text-sm font-semibold text-neutral-600">AM</p>
				</div>

				<div>
					<IconArrowNarrowRight class="text-[#0285FF]" />
				</div>

				<div class="flex items-baseline">
					<p class="text-[1.25rem] font-semibold text-neutral-800 tabular-nums">3:00</p>
					<p class="text-sm font-semibold text-neutral-600">PM</p>
				</div>
			</div>

			<div class="flex items-baseline rounded-3xl bg-neutral-400/40 px-4.5 py-1.5">
				<p class="font-semibold text-neutral-800 tabular-nums">12</p>
				<p class="text-sm font-semibold text-neutral-600">mins</p>
			</div>

			<div class="flex items-baseline rounded-3xl bg-neutral-400/40 px-4.5 py-1.5">
				<p class="font-semibold text-neutral-800 tabular-nums">22</p>
				<p class="text-sm font-semibold text-neutral-600">mins</p>
			</div>
		</div>

		<div class="flex justify-between px-3 pt-2">
			<div class="flex h-6 items-center px-2">
				<IconStopwatch class="text-[#0285FF]" size={22} />
				<p class="text-[0.9rem] font-semibold text-[#0285FF]">6:15hr</p>
			</div>

			<button
				class="flex h-6 w-6 items-center justify-center rounded-full bg-neutral-600 text-white"
			>
				<IconPlus stroke={3} size={16} />
			</button>
		</div>
	</div>
</div>

<div class="flex gap-3 overflow-x-scroll bg-neutral-200/80 p-4">
	<div class="w-fit shrink-0 rounded-3xl bg-white p-2">
		<!-- Title -->
		<div class="flex items-center gap-1.5">
			<div
				class="flex h-8 w-8 items-center justify-center rounded-full bg-linear-to-b from-orange-400 to-amber-700"
			>
				<IconPackage class="text-neutral-100" size={21} />
			</div>
			<p class="text-xl font-semibold tracking-tight-md">Materials</p>
			<div class="grow"></div>
			<button class="flex h-8 w-13 items-center justify-center rounded-full bg-sky-100 py-1">
				<IconPlus size={19} stroke={3} class="text-sky-600" />
			</button>
		</div>
		<!-- Contents -->
		<div class="flex min-h-18 items-center justify-center">
			<p class="text-lg font-semibold tracking-tight text-neutral-400">It's looking pretty empty</p>
		</div>
	</div>

	<div class="w-fit shrink-0 rounded-3xl bg-white p-2">
		<!-- Title -->
		<div class="flex items-center justify-center gap-1.5">
			<div
				class="flex h-8 w-8 items-center justify-center rounded-full bg-linear-to-b from-green-400 to-green-600"
			>
				<IconClipboardCheckFilled class="text-neutral-100" size={21} />
			</div>
			<p class="text-xl font-semibold tracking-tight-md">Work Done</p>
			<div class="grow"></div>
			<button class="flex h-8 w-13 items-center justify-center rounded-full bg-sky-100 py-1">
				<IconPlus size={19} stroke={3} class="text-sky-600" />
			</button>
		</div>
		<!-- Contents -->
		<div class="flex min-h-18 items-center justify-center">
			<p class="text-lg font-semibold tracking-tight text-neutral-400">It's looking pretty empty</p>
		</div>
	</div>

	<div class="w-fit shrink-0 rounded-3xl bg-white p-2">
		<!-- Title -->
		<div class="flex items-center justify-center gap-1.5">
			<div
				class="flex h-8 w-8 items-center justify-center rounded-full bg-linear-to-b from-purple-400 to-purple-600"
			>
				<IconFileCheckFilled class="text-neutral-100" size={21} />
			</div>
			<p class="text-xl font-semibold tracking-tight-md">Job Type</p>
			<div class="grow"></div>
			<button class="flex h-8 w-13 items-center justify-center rounded-full bg-sky-100 py-1">
				<IconPlus size={19} stroke={3} class="text-sky-600" />
			</button>
		</div>
		<!-- Contents -->
		<div class="flex min-h-18 items-center justify-center">
			<p class="text-lg font-semibold tracking-tight text-neutral-400">It's looking pretty empty</p>
		</div>
	</div>

	<div
		class="flex h-fit w-fit items-center gap-1 rounded-full p-1 pr-3 outline-2 outline-neutral-500"
	>
		<IconCircleArrowRightFilled class="text-neutral-500" />
		<p class="font-medium">Submit</p>
	</div>
</div>
