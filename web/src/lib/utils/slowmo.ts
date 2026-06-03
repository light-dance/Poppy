import slowmo from 'slowmo'
import { browser } from '$app/environment'

export function setSlowmo(speed: number) {
	if (browser) {
		slowmo(speed)
	}
}
