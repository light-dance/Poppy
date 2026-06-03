import { metaLoad } from '@opensky/seo'
import { site } from '$lib/site-config'

export const load = metaLoad.layout({
	sitename: `${site.name} Office`,
	icon: '/favicon.svg',
	title: `${site.name}`,
	titleTemplate: { route: '/', template: `${site.name} - {page}` },
	description: 'Time and material billing for contractors'
})
