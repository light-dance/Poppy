// Color components
export { default as HTMLBackground } from './html.svelte'
export { default as BodyBackground } from './body.svelte'

// Component family for convenient importing
import HTMLBackground from './html.svelte'
import BodyBackground from './body.svelte'

export const Color = {
	HTMLBackground,
	BodyBackground
}
