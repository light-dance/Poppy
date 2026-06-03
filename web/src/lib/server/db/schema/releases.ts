import { sql } from 'drizzle-orm'
import { index, integer, sqliteTable, text } from 'drizzle-orm/sqlite-core'

export const releases = sqliteTable(
	'releases',
	{
		buildNumber: integer('build_number').primaryKey(),
		version: text('version').notNull(),
		title: text('title').notNull().default(''),
		changelog: text('changelog').notNull().default(''),
		publishedAt: integer('published_at', { mode: 'timestamp' })
			.notNull()
			.default(sql`(unixepoch())`),
		createdAt: integer('created_at', { mode: 'timestamp' })
			.notNull()
			.default(sql`(unixepoch())`),
		updatedAt: integer('updated_at', { mode: 'timestamp' })
			.notNull()
			.default(sql`(unixepoch())`)
	},
	(table) => [
		index('releases_version_idx').on(table.version),
		index('releases_published_at_idx').on(table.publishedAt)
	]
)
