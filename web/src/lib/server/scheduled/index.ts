import { scheduleAuthCleanup } from './tasks/auth-cleanup'
import { scheduleStorageUploadsCleanup } from './tasks/storage-uploads-cleanup'

export function scheduledTasks() {
	console.log('Starting scheduled tasks')

	scheduleAuthCleanup()
	scheduleStorageUploadsCleanup()
}
