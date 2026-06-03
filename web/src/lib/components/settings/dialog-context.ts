import { createContext } from 'svelte'

interface Dialog {
	/**
	 * Triggers reauth dialog for sensitive operations.
	 * Resolves true if user reauthenticates, false if cancelled.
	 */
	requireRecentAuth: () => Promise<boolean>

	/**
	 * Getter for current expanded accordion section ID.
	 * Returns a function to maintain reactivity.
	 */
	accordionValue: () => string

	/**
	 * Scrolls the settings dialog to top.
	 * Called when opening nested dialogs.
	 */
	scrollToTop: () => void

	/**
	 * Sets the height of nested dialogs.
	 * Pass 0 to clear when dialog closes.
	 */
	setNestedDialogHeight: (height: number) => void

	/**
	 * Sets the height of reauth dialog.
	 * Takes priority over nested dialog height.
	 */
	setReauthDialogHeight: (height: number) => void
}

export const [getDialogContext, setDialogContext] = createContext<Dialog>()
