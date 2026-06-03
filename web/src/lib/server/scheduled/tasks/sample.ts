import { Cron } from 'croner'
import { EVERY_12_HOURS } from '../schedules'

export function scheduleSample() {
	const schedule = new Cron(
		EVERY_12_HOURS,
		async () => {
			console.log('[SCHEDULED] Running sample job')
		},
		{
			timezone: 'UTC'
		}
	)
	return schedule
}
