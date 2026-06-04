import { mkdirSync } from 'fs'
import { dirname } from 'path'
import { Database } from 'bun:sqlite'
import { drizzle } from 'drizzle-orm/bun-sqlite'

import * as schema from '../../src/lib/server/db/schema'

const dbFile = process.env.DB_URL ?? './db/data.sqlite'

if (dbFile !== ':memory:') {
	mkdirSync(dirname(dbFile), { recursive: true })
}

const client = new Database(dbFile)
client.run('PRAGMA foreign_keys = ON')

const db = drizzle({ client, schema })

// Start Seeding Database
export async function seed() {
	console.log('🌱 Seeding database...')

	try {
		await db
			.insert(schema.releases)
			.values({
				version: '0.0.0',
				title: 'Development release',
				changelog: 'Local seed release for testing the download and changelog pages.'
			})
			.onConflictDoUpdate({
				target: schema.releases.version,
				set: {
					title: 'Development release',
					changelog: 'Local seed release for testing the download and changelog pages.',
					updatedAt: new Date()
				}
			})

		console.log('✅ Database seeded successfully')
	} catch (error) {
		console.error('❌ Error seeding database:', error)
		throw error
	} finally {
		client.close()
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
