import { Spring } from 'svelte/motion'

export interface ToastBounceConfig {
	/** Scale factor for X axis during bounce */
	scaleX: number
	/** Scale factor for Y axis during bounce */
	scaleY: number
	/** Duration in ms to hold the bounce scale before returning to normal */
	holdDuration: number
	/** Spring stiffness for bounce animation */
	stiffness: number
	/** Spring damping for bounce animation */
	damping: number
}

export const DEFAULT_BOUNCE_CONFIG: ToastBounceConfig = {
	scaleX: 1.05,
	scaleY: 1.2,
	holdDuration: 115,
	stiffness: 0.3,
	damping: 0.8
}

export interface ToastBounceReturn {
	/** Spring for X scale */
	scaleX: Spring<number>
	/** Spring for Y scale */
	scaleY: Spring<number>
	/** Trigger bounce animation */
	triggerBounce: () => void
	/** Reset springs to normal scale */
	reset: () => void
}

/**
 * Creates reusable bounce behavior for toast components
 */
export function createToastBounce(config: Partial<ToastBounceConfig> = {}): ToastBounceReturn {
	const finalConfig = { ...DEFAULT_BOUNCE_CONFIG, ...config }

	const scaleX = new Spring(1, {
		stiffness: finalConfig.stiffness,
		damping: finalConfig.damping
	})

	const scaleY = new Spring(1, {
		stiffness: finalConfig.stiffness,
		damping: finalConfig.damping
	})

	let bounceTimeout: ReturnType<typeof setTimeout> | undefined

	const triggerBounce = () => {
		// Clear any existing bounce timeout
		if (bounceTimeout) {
			clearTimeout(bounceTimeout)
		}

		// Set bounce scale values
		scaleX.set(finalConfig.scaleX)
		scaleY.set(finalConfig.scaleY)

		// Return to normal after hold duration
		bounceTimeout = setTimeout(() => {
			scaleX.set(1)
			scaleY.set(1)
			bounceTimeout = undefined
		}, finalConfig.holdDuration)
	}

	const reset = () => {
		if (bounceTimeout) {
			clearTimeout(bounceTimeout)
			bounceTimeout = undefined
		}
		scaleX.set(1)
		scaleY.set(1)
	}

	return {
		scaleX,
		scaleY,
		triggerBounce,
		reset
	}
}
