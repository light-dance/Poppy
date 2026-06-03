import { sections, items } from '../../src/lib/server/db/schema'
import { generateNKeysBetween } from '../../src/lib/utils/fractional-indexes'
import type { PostgresJsDatabase } from 'drizzle-orm/postgres-js'

type SectionDef = {
	title: string
	icon: string
	column: number
	items: { name: string; cost: string; quantityType: string }[]
}

const sectionData: SectionDef[] = [
	// Column 0
	{
		title: 'Prewire & Cable',
		icon: 'plug-connected',
		column: 0,
		items: [
			{ name: '1G LV NAIL ON', cost: '900.00', quantityType: 'whole_unit' },
			{ name: '1 1/2" INNER DUCT (ORG)', cost: '0.00', quantityType: 'ft' },
			{ name: '1G LV RING (LV-1)', cost: '0.00', quantityType: 'whole_unit' },
			{ name: '2G LV RING (LV-2)', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'SPEAKER LV RING', cost: '0.00', quantityType: 'whole_unit' },
			{ name: '1G VINYL BLOCK WP BOX', cost: '0.00', quantityType: 'whole_unit' },
			{ name: '14X14 DISTR BOX', cost: '0.00', quantityType: 'whole_unit' },
			{ name: '14X14 DISTR DOOR', cost: '0.00', quantityType: 'whole_unit' },
			{ name: '8" TIE WRAPS', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'ROMEX STAPLES', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'NAIL PLATE', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'CAT5E RISER CABLE', cost: '0.00', quantityType: 'ft' },
			{ name: 'CAT6 RISER CABLE', cost: '0.00', quantityType: 'ft' },
			{ name: 'RG6 COAX CABLE', cost: '0.00', quantityType: 'ft' },
			{ name: '22/2 SPEAKER CABLE', cost: '0.00', quantityType: 'ft' },
			{ name: '22/4 SPEAKER CABLE', cost: '0.00', quantityType: 'ft' },
			{ name: '18/2 SPEAKER CABLE', cost: '0.00', quantityType: 'ft' },
			{ name: '18/4 SPEAKER CABLE', cost: '0.00', quantityType: 'ft' },
			{ name: '16/2 SPEAKER CABLE', cost: '0.00', quantityType: 'ft' },
			{ name: 'Cat5e Burial reed', cost: '0.00', quantityType: 'ft' },
			{ name: 'FIBER', cost: '0.00', quantityType: 'ft' }
		]
	},
	{
		title: 'Faceplate & Trimout',
		icon: 'box',
		column: 0,
		items: [
			{ name: 'FP 1G 1P KEYSTONE', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'FP 1G 2P KEYSTONE', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'FP 1G 4P KEYSTONE', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'FP 1G 6P KEYSTONE', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'FP 1G BLANK', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'FP 2G BLANK', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'FP 1G BRUSH', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'FP 1G F CONN', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'FP 1G TELCO', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'FP 1G TELCO & F CONN', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'FP (2) GANG DECORA/GFCI', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'FP (3) GANG DECORA/GFCI', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'FP (4) GANG DECORA/GFCI', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'MEDIA PANEL 1X8 COAX SPLITTER', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'COAX 1 X ( ) SPLITTER', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'MEDIA PANEL 8 PORT VOICE HUB', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'IR KIT/RCVR/3.5/PS', cost: '0.00', quantityType: 'whole_unit' },
			{ name: '12 PORT FP 2G WHITE', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'Floor Box', cost: '0.00', quantityType: 'whole_unit' },
			{ name: '2P yoke', cost: '0.00', quantityType: 'whole_unit' }
		]
	},
	{
		title: 'Cable Ends & Jacks',
		icon: 'package',
		column: 0,
		items: [
			{ name: 'F CONN CRIMP (Klein brand)', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'RJ45 EZ-CRIMP', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'CAT5E KEYSTN INSERT', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'CAT6 KEYSTN INSERT', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'F CONN KEYSTN INSERT', cost: '0.00', quantityType: 'whole_unit' }
		]
	},
	// Column 1
	{
		title: 'Alarm/Security',
		icon: 'shield',
		column: 1,
		items: [
			{ name: 'GC3 panel', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'Edge Panel', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'DW contact', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'PIR motion', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'Keyfob', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'Verizon cell radio', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'Glass break', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'Firefighter', cost: '0.00', quantityType: 'whole_unit' }
		]
	},
	{
		title: 'Sound, AV, & Automation',
		icon: 'device-speaker',
		column: 1,
		items: [
			{ name: 'C641 speakers (pair)', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'C651 center (each)', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'IW530 in-wall (each)', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'C635 outdoor (pair)', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'PS8 8" subwoofer', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'HDMI 12', cost: '0.00', quantityType: 'whole_unit' }
		]
	},
	// Column 2
	{
		title: 'Labor',
		icon: 'users',
		column: 2,
		items: [
			{ name: 'Mechanic labor', cost: '0.00', quantityType: 'hrs' },
			{ name: 'Helper labor', cost: '0.00', quantityType: 'hrs' },
			{ name: 'Pete labor', cost: '0.00', quantityType: 'hrs' },
			{ name: 'Rob labor', cost: '0.00', quantityType: 'hrs' },
			{ name: 'Cade labor', cost: '0.00', quantityType: 'hrs' }
		]
	},
	{
		title: 'Central Vac',
		icon: 'microwave',
		column: 2,
		items: [
			{ name: '3 INLET ROUGHIN KIT (NO PIPE)', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'VAC WALL INLET (ROUGHIN)', cost: '0.00', quantityType: 'whole_unit' },
			{ name: "VAC PIPE 8' SECTION", cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'FLEX TUBING 36"', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'ROLL OF PLAST STRAP (By FT)', cost: '0.00', quantityType: 'ft' },
			{ name: '18/2 CABLE(By FT)', cost: '0.00', quantityType: 'ft' },
			{ name: 'PVC GLUE (By Can)', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'COUPLING', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'SHORT 90 ELBOW', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'LONG 90 ELBOW', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'STREET 90 ELBOW', cost: '0.00', quantityType: 'whole_unit' },
			{ name: '45 ELBOW', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'STREET 45 ELBOW', cost: '0.00', quantityType: 'whole_unit' },
			{ name: '90 T-Y', cost: '0.00', quantityType: 'whole_unit' },
			{ name: '45 Y', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'TUBING END CAP', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'VAC WALL INLET (TRIMOUT)', cost: '0.00', quantityType: 'whole_unit' },
			{ name: 'VAC PAN (KICK SPACE)', cost: '0.00', quantityType: 'whole_unit' }
		]
	}
]

export async function seedInventory(
	db: PostgresJsDatabase<typeof import('../../src/lib/server/db/schema')>
) {
	// Generate order keys for all sections
	const sectionOrderKeys = generateNKeysBetween(null, null, sectionData.length)

	for (let i = 0; i < sectionData.length; i++) {
		const section = sectionData[i]
		const sectionOrder = sectionOrderKeys[i]

		// Insert section
		const [insertedSection] = await db
			.insert(sections)
			.values({
				title: section.title,
				icon: section.icon,
				column: section.column,
				order: sectionOrder
			})
			.returning()

		// Generate order keys for items in this section
		const itemOrderKeys = generateNKeysBetween(null, null, section.items.length)

		// Insert items
		for (let j = 0; j < section.items.length; j++) {
			const item = section.items[j]
			await db.insert(items).values({
				sectionId: insertedSection.id,
				name: item.name,
				cost: item.cost,
				quantityType: item.quantityType,
				order: itemOrderKeys[j]
			})
		}
	}

	console.log('Inventory seed data inserted successfully!')
}
