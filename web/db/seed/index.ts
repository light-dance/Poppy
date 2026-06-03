import { SQL } from 'bun'
import { drizzle } from 'drizzle-orm/bun-sql'

import * as schema from '../../src/lib/server/db/schema'
import { relations } from '../../src/lib/server/db/relations'

import { seedInventory } from './inventory'

if (!process.env.DB_URL) throw new Error('DB_URL is not set')

const client = new SQL(process.env.DB_URL)
const db = drizzle({ client, schema, relations })

// Start Seeding Database
export async function seed() {
	console.log('🌱 Seeding database...')

	try {
		await seedInventory(db)
		console.log('✅ Database seeded successfully')
	} catch (error) {
		console.error('❌ Error seeding database:', error)
		throw error
	} finally {
		await client.end()
	}
}

// Run seeds if called directly
if (import.meta.main) {
	seed()
		.then(() => process.exit(0))
		.catch((error) => {
			console.error(error)
			process.exit(1)
		})
}
