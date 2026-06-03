<script lang="ts">
	import { Popover, RadioGroup } from 'bits-ui'
	import { createClass } from '@opensky/style'
	import { updateSectionIcon } from '$remotes/dayticket.remote'

	import {
		IconUsers,
		IconPackage,
		IconBox,
		IconMicrowave,
		IconPlugConnected,
		IconDeviceRemote,
		IconDeviceTv,
		IconGhost3,
		IconDeviceSpeaker,
		IconMicrophone,
		IconCar,
		IconBulb,
		IconStar,
		IconPrinter,
		IconClipboardText,
		IconShield
	} from '@tabler/icons-svelte'

	const icons = [
		{ value: 'box', component: IconBox },
		{ value: 'users', component: IconUsers },
		{ value: 'package', component: IconPackage },
		{ value: 'microwave', component: IconMicrowave },
		{ value: 'plug-connected', component: IconPlugConnected },
		{ value: 'device-remote', component: IconDeviceRemote },
		{ value: 'device-tv', component: IconDeviceTv },
		{ value: 'ghost', component: IconGhost3 },
		{ value: 'device-speaker', component: IconDeviceSpeaker },
		{ value: 'microphone', component: IconMicrophone },
		{ value: 'car', component: IconCar },
		{ value: 'bulb', component: IconBulb },
		{ value: 'star', component: IconStar },
		{ value: 'printer', component: IconPrinter },
		{ value: 'clipboard-text', component: IconClipboardText },
		{ value: 'shield', component: IconShield }
	] as const

	type IconValue = (typeof icons)[number]['value']

	interface Props {
		sectionId: string
		icon?: string | null
	}

	let { sectionId, icon = 'box' }: Props = $props()

	function getInitialSelectedIcon() {
		return icons.some((i) => i.value === icon) ? (icon as IconValue) : 'box'
	}

	let selectedValue = $state<IconValue>(getInitialSelectedIcon())

	let SelectedIcon = $derived(icons.find((i) => i.value === selectedValue)?.component ?? IconBox)

	async function handleIconChange(newIcon: string) {
		selectedValue = newIcon as IconValue
		await updateSectionIcon({ sectionId, icon: newIcon }).run()
	}
</script>

<Popover.Root>
	<Popover.Trigger
		data-icon-selection
		class="rounded-lg px-1 py-1 hover:bg-neutral-300 data-[state=open]:bg-blue-100"
	>
		<SelectedIcon size={22} class="text-neutral-700 [[data-state=open]_&]:text-blue-500" />
	</Popover.Trigger>

	<Popover.Portal>
		<Popover.Content
			side="bottom"
			sideOffset={5}
			align="center"
			collisionPadding={5}
			class="z-50 flex w-fit rounded-2xl bg-black p-1 shadow-lg outline-none"
		>
			<RadioGroup.Root
				value={selectedValue}
				onValueChange={handleIconChange}
				class="grid grid-cols-4 gap-1"
			>
				{#each icons as { value, component: Icon } (value)}
					{@const isSelected = selectedValue === value}
					<RadioGroup.Item
						{value}
						class={createClass(
							'rounded-xl p-1.5 text-neutral-300',
							isSelected && 'bg-neutral-700 text-neutral-50'
						)}
					>
						<Icon />
					</RadioGroup.Item>
				{/each}
			</RadioGroup.Root>
		</Popover.Content>
	</Popover.Portal>
</Popover.Root>
