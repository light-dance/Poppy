<script lang="ts">
	import { IconChevronLeft, IconChevronRight, IconRestore } from '@tabler/icons-svelte'
	import {
		CalendarDate,
		startOfWeek,
		getLocalTimeZone,
		today,
		isSameDay
	} from '@internationalized/date'
	import { createClass } from '@opensky/style'

	let {
		selectedDate = $bindable(today(getLocalTimeZone())),
		onSelectedDateChange
	}: {
		selectedDate?: CalendarDate
		onSelectedDateChange?: (date: CalendarDate) => void
	} = $props()

	// Local state
	let scrollElement: HTMLDivElement

	const todayDate = today(getLocalTimeZone())
	const todayWeekStart = startOfWeek(todayDate, 'en-US')

	function generateTwoWeekPeriod(weeksOffset: number) {
		// For today to appear in the second week of a period,
		// the period must start one week before today's week
		const periodStart = todayWeekStart.add({ weeks: weeksOffset })

		const weeks = []
		for (let week = 0; week < 2; week++) {
			const weekStartDate = periodStart.add({ weeks: week })
			const weekDates = []

			for (let day = 0; day < 7; day++) {
				weekDates.push(weekStartDate.add({ days: day }))
			}
			weeks.push(weekDates)
		}

		return {
			startDate: periodStart,
			endDate: periodStart.add({ days: 13 }),
			weeks,
			weeksOffset
		}
	}

	// Generate periods where today appears in the second week of the "current" period
	// The current period should start 1 week before today's week (offset -1)
	const allPeriods = [-9, -7, -5, -3, -1, 1].map((offset) => generateTwoWeekPeriod(offset))

	const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']

	function formatDate(date: CalendarDate) {
		return date.toDate(getLocalTimeZone()).toLocaleDateString('en-US', {
			weekday: 'short',
			month: 'short',
			day: 'numeric'
		})
	}

	// Update visible month based on scroll position
	function handleScroll() {
		if (!scrollElement) return

		const scrollLeft = scrollElement.scrollLeft
		const containerWidth = scrollElement.offsetWidth
		const currentPeriodIndex = Math.round(scrollLeft / containerWidth)

		if (currentPeriodIndex >= 0 && currentPeriodIndex < allPeriods.length) {
			// Period is visible, could track currentVisibleMonth here if needed
		}
	}

	function goToPrevious() {
		if (scrollElement) {
			const containerWidth = scrollElement.offsetWidth
			scrollElement.scrollBy({
				left: -containerWidth,
				behavior: 'smooth'
			})
		}
	}

	function goToNext() {
		if (scrollElement) {
			const containerWidth = scrollElement.offsetWidth
			scrollElement.scrollBy({
				left: containerWidth,
				behavior: 'smooth'
			})
		}
	}

	function goToToday() {
		selectedDate = todayDate
		onSelectedDateChange?.(todayDate)

		if (scrollElement) {
			// Today appears in the period with offset -1, which is at index 4
			const todayPeriodIndex = 4
			const containerWidth = scrollElement.offsetWidth
			scrollElement.scrollTo({
				left: todayPeriodIndex * containerWidth,
				behavior: 'smooth'
			})
		}
	}

	function selectDate(date: CalendarDate) {
		selectedDate = date
		onSelectedDateChange?.(date)
	}

	function getDateClasses(date: CalendarDate) {
		const isToday = isSameDay(date, todayDate)
		const isSelected = isSameDay(date, selectedDate)
		const isFuture = date.compare(todayDate) > 0

		return createClass(
			'relative h-12 w-full flex items-center justify-center text-[1.1rem] font-medium rounded-full transition-all cursor-pointer active:scale-95',
			'text-neutral-200 bg-transparent hover:bg-neutral-400/50',
			isToday && 'text-rose-600 font-bold',
			isFuture && 'text-neutral-600',
			isSelected && 'text-sky-100'
		)
	}

	// Initialize scroll position to today's period
	$effect(() => {
		if (scrollElement) {
			// Today appears in the period with offset -1, which is at index 4
			const todayPeriodIndex = 4
			const containerWidth = scrollElement.offsetWidth
			scrollElement.scrollLeft = todayPeriodIndex * containerWidth
		}
	})
</script>

<div
	class="w-full overflow-hidden rounded-3xl bg-neutral-800 py-2 shadow-[inset_0_1px_1.5px_rgba(255,255,255,0.09),inset_0_-1px_4px_rgba(255,255,255,0.03)]"
>
	<!-- Header -->
	<div class="border-b border-neutral-600 px-2 pb-2">
		<div class="flex items-center gap-3">
			<!-- Left side - Month and Date -->
			<div class="pl-3">
				<p
					class="shrink-0 text-xl font-medium tracking-tight-sm whitespace-nowrap text-neutral-100"
				>
					{formatDate(selectedDate)}
				</p>
			</div>

			<div class="w-full grow"></div>

			<!-- Right side - Navigation -->
			<div class="flex items-center gap-2">
				{#if !isSameDay(selectedDate, todayDate)}
					<button
						onclick={goToToday}
						class="flex items-center gap-1.5 rounded-full bg-linear-to-b from-red-500/15 to-rose-500/15 px-4 py-2 pl-3 active:scale-95"
						aria-label="Go to today"
					>
						<IconRestore size={16} stroke={2.5} class="text-rose-500" />
						<p class="font-mono text-sm font-semibold tracking-tight text-rose-500">Today</p>
					</button>
				{/if}

				<button
					onclick={goToPrevious}
					class="rounded-full p-2 text-neutral-300 transition-colors hover:bg-neutral-700"
					aria-label="Previous period"
				>
					<IconChevronLeft size={21} stroke={2.5} />
				</button>

				<button
					onclick={goToNext}
					class="rounded-full p-2 text-neutral-300 transition-colors hover:bg-neutral-700"
					aria-label="Next period"
				>
					<IconChevronRight size={21} stroke={2.5} />
				</button>
			</div>
		</div>
	</div>

	<!-- Scrollable Calendar Container -->
	<div
		bind:this={scrollElement}
		onscroll={handleScroll}
		class="flex overflow-x-auto"
		style="scroll-snap-type: x mandatory; -ms-overflow-style: none; scrollbar-width: none;"
	>
		{#each allPeriods as period (period.weeksOffset)}
			<div class="min-w-full shrink-0 px-4" style="scroll-snap-align: start;">
				<div class="h-full w-full">
					<!-- Weekday Headers -->
					<div class="grid grid-cols-7 gap-1">
						{#each weekdays as day (day)}
							<div
								class={createClass(
									'py-2 text-center text-[0.85rem] font-medium text-neutral-400 uppercase',
									(day === 'Sun' || day === 'Sat') && 'text-neutral-500'
								)}
							>
								{day}
							</div>
						{/each}
					</div>

					<!-- Date Grid -->
					<div class="space-y-1">
						{#each period.weeks as week (week)}
							<div class="grid grid-cols-7 gap-1">
								{#each week as date (date)}
									<button onclick={() => selectDate(date)} class={getDateClasses(date)}>
										<div
											class={createClass(
												'absolute inset-0 z-0 h-full w-full rounded-full bg-linear-to-b from-blue-500 to-sky-500 transition-opacity',
												isSameDay(date, selectedDate) ? 'opacity-100' : 'opacity-0'
											)}
										></div>
										<div class="z-10">
											{date.day}
										</div>
									</button>
								{/each}
							</div>
						{/each}
					</div>
				</div>
			</div>
		{/each}
	</div>
</div>

<style>
	.overflow-x-auto::-webkit-scrollbar {
		display: none;
	}
</style>
