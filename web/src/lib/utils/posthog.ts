import { browser, dev } from '$app/environment'
import posthogSDK from 'posthog-js'
import { PUBLIC_POSTHOG_KEY, PUBLIC_POSTHOG_HOST } from '$env/static/public'

let initialized = false

export const posthog = {
	/** Initialize PostHog. Initializes in dev to allow testing feature flags, etc */
	init() {
		if (!browser) return
		if (initialized) return

		posthogSDK.init(PUBLIC_POSTHOG_KEY, {
			api_host: PUBLIC_POSTHOG_HOST,
			capture_pageview: false,
			capture_pageleave: !dev,
			persistence: 'localStorage+cookie'
		})

		initialized = true
	},

	/** Capture a pageview event. Call on every navigation. */
	pageView() {
		if (!browser) return
		if (dev) return

		posthogSDK.capture('$pageview')
	},

	/** Capture a custom event with optional properties. */
	event(event: string, properties?: Record<string, unknown>) {
		if (!browser) return
		if (dev) return

		posthogSDK.capture(event, properties)
	},

	/** Link future events to a user ID. Call after login. */
	identifyUser(userId: string, properties?: Record<string, unknown>) {
		if (!browser) return
		if (dev) return

		posthogSDK.identify(userId, properties)
	},

	/** Clear user identity. Call on logout. */
	resetUser() {
		if (!browser) return
		if (dev) return

		posthogSDK.reset()
	}
}
