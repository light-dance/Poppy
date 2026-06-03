export type ConfirmationState = 'idle' | 'confirmationStep' | 'confirmed' | 'cancelled'

export type ConfirmationOptions = {
	/**
	 * Optional gate that runs before showing the confirmation step.
	 * Return `false` to keep the confirmation closed.
	 */
	onRequest?: () => boolean | Promise<boolean>
	/** Runs when the user confirms. */
	onConfirm?: () => void | Promise<void>
	/** Runs when the user cancels. */
	onCancel?: () => void | Promise<void>
}

/**
 * Reusable state machine for confirmation UI flows.
 *
 * @param options - Lifecycle callbacks for request/confirm/cancel.
 * @example
 * ```ts
 * const confirmation = new Confirmation({
 * 	onConfirm: async () => {
 * 		await deleteThing()
 * 	},
 * 	onCancel: () => {
 * 		console.log('User cancelled')
 * 	}
 * })
 *
 * await confirmation.request()
 * ```
 */
export class Confirmation {
	private options: ConfirmationOptions

	state = $state<ConfirmationState>('idle')
	pending = $state(false)

	confirmationStep = $derived(this.state === 'confirmationStep')
	confirmed = $derived(this.state === 'confirmed')
	cancelled = $derived(this.state === 'cancelled')
	idle = $derived(this.state === 'idle')

	constructor(options: ConfirmationOptions = {}) {
		this.options = options
	}

	/**
	 * Opens the confirmation step when allowed.
	 *
	 * @returns `true` when the confirmation is opened, otherwise `false`.
	 */
	async request() {
		if (this.pending) return false

		if (this.options.onRequest) {
			const canContinue = await this.options.onRequest()
			if (!canContinue) return false
		}

		this.state = 'confirmationStep'
		return true
	}

	/**
	 * Marks the flow as confirmed and runs `onConfirm`.
	 *
	 * @returns `true` when a confirm transition occurred.
	 */
	async confirm() {
		if (this.pending || this.state !== 'confirmationStep') return false

		this.pending = true
		this.state = 'confirmed'

		try {
			await this.options.onConfirm?.()
			return true
		} finally {
			this.pending = false
			this.state = 'idle'
		}
	}

	/**
	 * Marks the flow as cancelled and runs `onCancel`.
	 *
	 * @returns `true` when a cancel transition occurred.
	 */
	async cancel() {
		if (this.pending || this.state !== 'confirmationStep') return false

		this.pending = true
		this.state = 'cancelled'

		try {
			await this.options.onCancel?.()
			return true
		} finally {
			this.pending = false
			this.state = 'idle'
		}
	}

	/** Resets the flow back to idle. */
	reset() {
		if (this.pending) return
		this.state = 'idle'
	}
}
