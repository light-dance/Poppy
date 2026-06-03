import { AUTUMN_SECRET_KEY } from '$env/static/private'
import { Autumn } from 'autumn-js'

import { defineCheck } from '../types'

const autumn = new Autumn({ secretKey: AUTUMN_SECRET_KEY })

type PlanLevel = 'pro' | 'free' | null

export default defineCheck<PlanLevel, [level?: 'pro' | 'free']>({
	resolve: async (event, level?) => {
		// Check for user
		const user = event.locals.user
		if (!user) return { value: null, allowed: false, message: 'Not authenticated' }

		// Use hook-populated value if already set
		// otherwise check with autumn
		let plan: PlanLevel
		if (event.locals.access.plan !== null) {
			plan = event.locals.access.plan
		} else {
			try {
				const result = await autumn.check({ customerId: user.id, featureId: 'pro' })
				plan = result.allowed ? 'pro' : 'free'
			} catch (err) {
				console.error('[access:plan] Failed to resolve plan from Autumn:', err)
				plan = null
			}
		}

		// Check against required level
		if (level === 'pro' && plan !== 'pro') {
			return { value: plan, allowed: false, message: 'Pro plan required' }
		}
		if (plan === null) {
			return { value: plan, allowed: false, message: 'No active plan' }
		}

		return { value: plan, allowed: true }
	}
})
