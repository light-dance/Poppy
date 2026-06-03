<script lang="ts">
	import { createClass } from '@opensky/style'
	import {
		IconArrowUp,
		IconCalendarWeekFilled,
		IconMapPinFilled,
		IconBuildings,
		IconReceiptDollarFilled,
		IconArrowBackUp
	} from '@tabler/icons-svelte'
	import { Tooltip, Popover } from 'bits-ui'
	import InputAdapting from '$ui/input/input-adapting.svelte'
	import { today, getLocalTimeZone, isSameDay } from '@internationalized/date'
	import { wipeHorizontal } from '$ui/transition'
	import DatePicker from './date.svelte'

	type Props = {
		togglePanel: () => void
	}
	let { togglePanel }: Props = $props()

	let isSubmitAvailable = $state(false)
	let datePickerOpen = $state(false)

	let date = $state(today(getLocalTimeZone()))
	let builder = $state('')
	let lot = $state('')
	let billing = $state('')

	let isToday = $derived(isSameDay(date, today(getLocalTimeZone())))
	let dateString = $derived(
		date
			.toDate(getLocalTimeZone())
			.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' })
	)
</script>

<div
	class="pointer-events-auto flex h-fit w-fit items-center gap-1 rounded-4xl bg-[#FAF8FB] px-2 py-1 shadow-[inset_0_1px_1.5px_rgba(255,255,255,1),0_1px_1.5px_0px_rgba(0,0,0,0.08),0_2px_30px_11px_rgba(0,0,0,0.04)]"
>
	<Tooltip.Provider delayDuration={600}>
		<Tooltip.Root>
			<Tooltip.Trigger>
				{#snippet child({ props })}
					<button
						{...props}
						tabindex="-1"
						class="flex aspect-square h-8 w-8 items-center justify-center rounded-full bg-linear-to-b from-orange-400 to-orange-600 p-2"
					>
						<p class="font-semibold tracking-tight text-white/80">SP</p>
					</button>
				{/snippet}
			</Tooltip.Trigger>
			{@render tooltipContent('Account')}
		</Tooltip.Root>

		<div class="ml-1 h-full min-h-8 w-0.5 rounded-full bg-neutral-200"></div>

		<!-- Date -->
		<Popover.Root bind:open={datePickerOpen}>
			<Tooltip.Root disabled={datePickerOpen}>
				<Tooltip.Trigger>
					{#snippet child({ props: tooltipProps })}
						<Popover.Trigger>
							{#snippet child({ props: popoverProps })}
								<button
									{...tooltipProps}
									{...popoverProps}
									class={createClass(
										'flex min-h-8 w-fit shrink-0 cursor-pointer items-center gap-1 rounded-full bg-neutral-300/0 px-3 will-change-transform hover:bg-neutral-200/80 active:scale-95',
										datePickerOpen && 'bg-neutral-200/80'
									)}
								>
									<IconCalendarWeekFilled size={22} class="shrink-0 grow text-rose-600" />
									{#if isToday}
										<p
											transition:wipeHorizontal={{ duration: 125 }}
											class="w-fit shrink-0 grow font-normal whitespace-nowrap text-neutral-500"
										>
											Today
										</p>
									{/if}
									<p class="w-fit shrink-0 grow font-medium whitespace-nowrap text-neutral-800">
										{dateString}
									</p>
								</button>
							{/snippet}
						</Popover.Trigger>
					{/snippet}
				</Tooltip.Trigger>
				{@render tooltipContent('Change Date')}
			</Tooltip.Root>
			<Popover.Portal>
				<Popover.Content
					side="top"
					sideOffset={4}
					align="start"
					class="z-100 w-96"
					trapFocus={false}
				>
					<DatePicker bind:selectedDate={date} />
				</Popover.Content>
			</Popover.Portal>
		</Popover.Root>

		<!-- Builder -->
		<Tooltip.Root>
			<Tooltip.Trigger>
				{#snippet child({ props })}
					<label
						{...props}
						tabindex="-1"
						class={createClass(
							'flex h-full min-h-8 cursor-pointer items-center gap-1 rounded-lg px-2 focus-within:bg-neutral-200/80 hover:bg-neutral-200/80'
						)}
					>
						<IconBuildings size={22} class="shrink-0 grow text-sky-500" />
						<InputAdapting
							class={createClass(
								'w-fit outline-none selection:bg-sky-200 selection:text-blue-600 placeholder:font-medium placeholder:tracking-tight-md',
								'placeholder:text-neutral-800 focus:placeholder:text-neutral-500'
							)}
							type="text"
							placeholderIsMinWidth={true}
							maxWidth="var(--container-3xs)"
							bind:value={builder}
							placeholder="Builder"
						/>
					</label>
				{/snippet}
			</Tooltip.Trigger>
			{@render tooltipContent('Edit Builder')}
		</Tooltip.Root>

		<!-- Lot -->
		<Tooltip.Root>
			<Tooltip.Trigger>
				{#snippet child({ props })}
					<label
						{...props}
						tabindex="-1"
						class={createClass(
							'flex h-full min-h-8 cursor-pointer items-center gap-1 rounded-lg px-2 focus-within:bg-neutral-200/80 hover:bg-neutral-200/80'
						)}
					>
						<IconMapPinFilled size={22} class="shrink-0 grow text-indigo-400" />
						<InputAdapting
							class={createClass(
								'w-fit outline-none selection:bg-sky-200 selection:text-blue-600 placeholder:font-medium placeholder:tracking-tight-md',
								'placeholder:text-neutral-800 focus:placeholder:text-neutral-500'
							)}
							type="text"
							placeholderIsMinWidth={true}
							maxWidth="var(--container-3xs)"
							bind:value={lot}
							placeholder="Lot"
						/>
					</label>
				{/snippet}
			</Tooltip.Trigger>
			{@render tooltipContent('Edit Lot')}
		</Tooltip.Root>

		<!-- Billing -->
		<Tooltip.Root>
			<Tooltip.Trigger>
				{#snippet child({ props })}
					<label
						{...props}
						tabindex="-1"
						class={createClass(
							'flex h-full min-h-8 cursor-pointer items-center gap-1 rounded-lg px-2 focus-within:bg-neutral-200/80 hover:bg-neutral-200/80'
						)}
					>
						<IconReceiptDollarFilled size={22} class="shrink-0 grow text-green-600" />
						<InputAdapting
							class={createClass(
								'w-fit outline-none selection:bg-sky-200 selection:text-blue-600 placeholder:font-medium placeholder:tracking-tight-md',
								'placeholder:text-neutral-800 focus:placeholder:text-neutral-500'
							)}
							type="text"
							placeholderIsMinWidth={true}
							maxWidth="var(--container-3xs)"
							bind:value={billing}
							placeholder="Billing"
						/>
					</label>
				{/snippet}
			</Tooltip.Trigger>
			{@render tooltipContent('Edit Billing')}
		</Tooltip.Root>

		<div class="h-full min-h-8 w-0.5 rounded-full bg-neutral-200"></div>

		<Tooltip.Root>
			<Tooltip.Trigger>
				{#snippet child({ props })}
					<button {...props} tabindex="-1" class="mr-2 ml-1 text-neutral-500">
						<IconArrowBackUp />
					</button>
				{/snippet}
			</Tooltip.Trigger>
			{@render tooltipContent('Undo/Clear')}
		</Tooltip.Root>

		<Tooltip.Root>
			<Tooltip.Trigger>
				{#snippet child({ props })}
					<button
						{...props}
						tabindex="-1"
						onclick={() => {
							togglePanel?.()
						}}
						class={createClass(
							'z-50 -mr-1 flex h-10 w-10 shrink-0 cursor-pointer items-center justify-center rounded-full bg-neutral-500 p-1.5 shadow-md transition-all',
							'active:scale-95',
							isSubmitAvailable
								? 'bg-neutral-800 text-white shadow-md'
								: 'bg-neutral-300/70 text-neutral-400 shadow-none'
						)}
					>
						<IconArrowUp stroke={3} size={26} />
					</button>
				{/snippet}
			</Tooltip.Trigger>
			{@render tooltipContent('Ready to Submit')}
		</Tooltip.Root>
	</Tooltip.Provider>
</div>

{#snippet tooltipContent(text: string)}
	<Tooltip.Content side="bottom" sideOffset={5} align="center" class="z-200">
		<div class="rounded-2xl bg-neutral-900 px-3 py-2 text-[0.9rem] font-semibold text-neutral-50">
			{text}
		</div>
	</Tooltip.Content>
{/snippet}
