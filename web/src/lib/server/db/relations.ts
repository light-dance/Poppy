import { defineRelations } from 'drizzle-orm'
import * as schema from './schema/index'

export const relations = defineRelations(schema, (r) => ({
	sections: {
		items: r.many.items({
			from: r.sections.id,
			to: r.items.sectionId
		})
	},
	items: {
		section: r.one.sections({
			from: r.items.sectionId,
			to: r.sections.id
		})
	}
}))
