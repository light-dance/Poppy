import { pgTable, text, decimal, timestamp, boolean } from 'drizzle-orm/pg-core'
import { sections } from './sections'
import { randomUUID } from 'crypto'

export const items = pgTable('items', {
	id: text('id')
		.primaryKey()
		.$defaultFn(() => randomUUID()),
	sectionId: text('section_id')
		.notNull()
		.references(() => sections.id, { onDelete: 'cascade' }),
	name: text('name').notNull(),
	cost: decimal('cost', { precision: 10, scale: 2 }).notNull(),
	quantityType: text('quantity_type').notNull().default('whole_unit'),
	order: text('order').notNull(),
	archived: boolean('archived').notNull().default(false),
	createdAt: timestamp('created_at', { mode: 'date', withTimezone: true }).defaultNow().notNull(),
	updatedAt: timestamp('updated_at', { mode: 'date', withTimezone: true }).defaultNow().notNull()
})
