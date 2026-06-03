import { feature, product, featureItem, priceItem } from 'atmn'

// Features
export const pro = feature({
	id: 'pro',
	name: 'Pro',
	type: 'boolean'
})

// Products
export const proMonthly = product({
	id: 'pro_monthly',
	name: 'Pro',
	group: 'Pro',
	items: [
		priceItem({
			price: 29.99,
			interval: 'month'
		}),

		featureItem({
			feature_id: pro.id,
			included_usage: 0
		})
	],
	free_trial: {
		duration: 'month',
		length: 1,
		unique_fingerprint: true,
		card_required: true
	}
})

export const proYearly = product({
	id: 'pro_yearly',
	name: 'Pro',
	group: 'Pro',
	items: [
		priceItem({
			price: 300,
			interval: 'year'
		}),

		featureItem({
			feature_id: pro.id,
			included_usage: 0
		})
	],
	free_trial: {
		duration: 'month',
		length: 1,
		unique_fingerprint: true,
		card_required: true
	}
})
