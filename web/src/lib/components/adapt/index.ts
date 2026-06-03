// Toast components
export { default as AdaptFit } from './fit.svelte'
export { default as AdaptReveal } from './reveal.svelte'
export { default as AdaptSwap } from './swap.svelte'
export { default as AdaptSwitch } from './switch.svelte'

// Component families for convenient importing
import AdaptFit from './fit.svelte'
import AdaptReveal from './reveal.svelte'
import AdaptSwap from './swap.svelte'
import AdaptSwitch from './switch.svelte'

export const Adapt = {
	Fit: AdaptFit,
	Reveal: AdaptReveal,
	Swap: AdaptSwap,
	Switch: AdaptSwitch
}

// Type exports for Adapt components
// Adapt.Switch types
export interface AdaptSwitchTriggerOptions<T = unknown> {
	data?: T
	duration?: number
}
export type AdaptSwitchChangeState<T = unknown> = (stateName: string, data?: T) => void
export type AdaptSwitchTrigger<T = unknown> = (
	stateName: string,
	options?: AdaptSwitchTriggerOptions<T>
) => void

// Adapt.Reveal types
export type AdaptRevealTrigger = () => void
export type AdaptRevealOpen = () => void
export type AdaptRevealClose = () => void

// Adapt.Swap types
export interface AdaptSwapTriggerOptions<T = unknown> {
	data?: T
	duration?: number
}
export type AdaptSwapTrigger<T = unknown> = (options?: AdaptSwapTriggerOptions<T>) => void
export type AdaptSwapOpen<T = unknown> = (data?: T) => void
export type AdaptSwapClose = () => void
