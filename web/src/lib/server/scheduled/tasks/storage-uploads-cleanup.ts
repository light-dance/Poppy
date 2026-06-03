import { Cron } from 'croner'
import { EVERY_1_HOUR } from '../schedules'
import { cleanupExpiredUploads } from '$lib/server/storage'

export function scheduleStorageUploadsCleanup() {
	const schedule = new Cron(
		EVERY_1_HOUR,
		async () => {
			console.log('[SCHEDULED] Running scheduled task cleaning up expired uploads')
			try {
				const { deleted, errors } = await cleanupExpiredUploads()
				if (deleted > 0 || errors > 0) {
					console.log(`Upload cleanup complete: ${deleted} deleted, ${errors} errors`)
				}
			} catch (e) {
				console.error('Something went wrong running scheduled upload cleanup task', e)
			}
		},
		{
			timezone: 'UTC'
		}
	)
	return schedule
}
