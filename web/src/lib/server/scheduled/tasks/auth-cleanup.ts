import { Cron } from 'croner'
import { EVERY_12_HOURS } from '../schedules'
import Auth from '$lib/server/auth'

export function scheduleAuthCleanup() {
	const schedule = new Cron(
		EVERY_12_HOURS,
		async () => {
			console.log('[SCHEDULED] Running scheduled task cleaning up auth db')
			try {
				await Auth.cleanup.challenges()
				await Auth.cleanup.sessions()
			} catch (e) {
				console.error('Something went wrong running scheduled auth cleanup task', e)
			}
		},
		{
			timezone: 'UTC'
		}
	)
	return schedule
}
