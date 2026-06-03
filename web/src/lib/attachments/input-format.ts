import { tick } from 'svelte'

/**
 * A Svelte action to format an input field according to a pattern.
 * The pattern is a string that contains placeholders:
 *   - '#' for a digit
 *   - '%' for a letter
 *   - '*' for any character
 * Everything else in the pattern is treated as a literal.
 *
 * @param {HTMLElement} element - The input element.
 * @param {string} pattern - The formatting pattern.
 */
export function formatInput(element: HTMLInputElement, pattern: string) {
	// If no pattern is provided, do nothing.
	if (!pattern) {
		console.warn('No pattern was passed to the formatInput action added to:', element)
		return { destroy: () => {} }
	}

	let isFormatting = false

	function format(val: string, { trailing = true } = {}): string {
		if (!val) return ''

		let formattedValue = ''
		let valueIndex = 0
		let patternIndex = 0

		const passthroughSymbols: { [key: string]: RegExp } = {
			'#': /\d/,
			'%': /[a-zA-Z]/,
			'*': /./
		}
		const isPassthroughChar = (char: string): boolean => {
			if (passthroughSymbols[char]) {
				return true
			} else {
				return false
			}
		}
		const applyMatch = (char: string) => {
			formattedValue += char
			valueIndex++
			patternIndex++
		}

		while (patternIndex < pattern.length && valueIndex < val.length) {
			const patternChar = pattern[patternIndex]
			const inputChar = val[valueIndex]

			if (isPassthroughChar(patternChar)) {
				// Pattern Character is a passthrough character (#, %, *)
				if (passthroughSymbols[patternChar].test(inputChar)) {
					applyMatch(inputChar) // Skip the input character if it doesn't match
				} else {
					valueIndex++ // Skip the input character if it doesn't match
				}
			} else {
				// Pattern Character is a literal character
				if (inputChar === patternChar) {
					applyMatch(inputChar) // Just copy it if it's correct
				} else {
					formattedValue += patternChar // Otherwise insert from pattern
					patternIndex++
					// Note: we don't advance `valueIndex` here so that the same inputChar is used for the next pattern position
				}
			}
		}

		// If there are leftover literal characters in the pattern, append them.
		if (trailing) {
			while (patternIndex < pattern.length) {
				const patternChar = pattern[patternIndex]
				if (isPassthroughChar(patternChar)) {
					break // Stops at next passthrough char
				}
				formattedValue += patternChar // Append literal char
				patternIndex++
			}
		}

		return formattedValue
	}

	async function handleInput(endDelete: boolean = false) {
		if (!pattern) return // Exit if no pattern is supplied
		if (isFormatting) return // If we are already formatting, do nothing

		const oldCursor = element.selectionStart ?? 0 // cursor position state
		const currentValue = element.value // input value state

		const formattedValue = format(currentValue, { trailing: !endDelete })

		if (formattedValue !== currentValue) {
			isFormatting = true // lock formatting

			let newCursor: number
			if (oldCursor === currentValue.length) {
				newCursor = formattedValue.length
			} else {
				const rawPrefix = currentValue.substring(0, oldCursor)
				const formattedPrefix = format(rawPrefix, { trailing: false })
				newCursor = formattedPrefix.length
			}

			element.value = formattedValue
			await tick() // wait for DOM to update
			element.setSelectionRange(newCursor, newCursor) // update cursor position

			isFormatting = false // unlock formatting
		}
	}
	let skipNextInput = false
	async function handleKeydown(event: KeyboardEvent) {
		if (event.key === 'Backspace') {
			const cursor = element.selectionEnd ?? 0
			// Only intervene if the caret is at the end.
			if (cursor === element.value.length && element.value.length > 0) {
				skipNextInput = true
				handleInput(true)
			}
		}
	}

	element.maxLength = pattern.length

	element.addEventListener('input', () => {
		if (skipNextInput) {
			skipNextInput = false
			return
		}
		handleInput(false)
	})
	element.addEventListener('keydown', handleKeydown)

	return {
		// Allow the action to update if the pattern changes.
		update(newPattern: string) {
			pattern = newPattern
		},
		destroy() {
			element.removeEventListener('input', () => handleInput(false))
			element.removeEventListener('keydown', handleKeydown)
		}
	}
}
