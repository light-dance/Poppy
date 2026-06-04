import { sql } from 'drizzle-orm'
import { index, integer, sqliteTable, text, uniqueIndex } from 'drizzle-orm/sqlite-core'

export const releases = sqliteTable(
	'releases',
	{
		version: text('version').notNull().primaryKey(),
		build: integer('build').notNull().default(1),
		title: text('title'),
		changelog: text('changelog').notNull().default(''),
		sparkleZipLength: integer('sparkle_zip_length'),
		sparkleZipSignature: text('sparkle_zip_signature'),
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
	(table) => [index('releases_published_at_idx').on(table.publishedAt)]
)
