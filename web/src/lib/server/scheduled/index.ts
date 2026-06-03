import { scheduleSample } from './tasks/sample'

export function scheduledTasks() {
	console.log('Starting scheduled tasks')

	scheduleSample()
}
