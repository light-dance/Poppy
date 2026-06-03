import { pgTable, text, timestamp, integer, boolean } from 'drizzle-orm/pg-core'
import { randomUUID } from 'crypto'

export const sections = pgTable('sections', {
	id: text('id')
		.primaryKey()
		.$defaultFn(() => randomUUID()),
	title: text('title').notNull(),
	icon: text('icon'),
	column: integer('column').notNull().default(0),
	order: text('order').notNull(),
	archived: boolean('archived').notNull().default(false),
	collapsed: boolean('collapsed').default(false),
	createdAt: timestamp('created_at', { mode: 'date', withTimezone: true }).defaultNow().notNull(),
	updatedAt: timestamp('updated_at', { mode: 'date', withTimezone: true }).defaultNow().notNull()
})
