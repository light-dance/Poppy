export { default as Button } from './button.svelte'
export { default as Textarea } from './textarea.svelte'
export { default as InputAdapting } from './input-adapting.svelte'
export { default as Toggle } from './toggle.svelte'

import InputButton from './button.svelte'
import InputAdapting from './input-adapting.svelte'
import Textarea from './textarea.svelte'
import Toggle from './toggle.svelte'

export const Input = {
	Button: InputButton,
	Textarea: Textarea,
	InputAdapting: InputAdapting,
	Toggle: Toggle
}

export type FormInputEvent<T extends Event = Event> = T & {
	currentTarget: EventTarget & HTMLInputElement
}
export type InputEvents = {
	blur: FormInputEvent<FocusEvent>
	change: FormInputEvent<Event>
	click: FormInputEvent<MouseEvent>
	focus: FormInputEvent<FocusEvent>
	focusin: FormInputEvent<FocusEvent>
	focusout: FormInputEvent<FocusEvent>
	keydown: FormInputEvent<KeyboardEvent>
	keypress: FormInputEvent<KeyboardEvent>
	keyup: FormInputEvent<KeyboardEvent>
	mouseover: FormInputEvent<MouseEvent>
	mouseenter: FormInputEvent<MouseEvent>
	mouseleave: FormInputEvent<MouseEvent>
	paste: FormInputEvent<ClipboardEvent>
	input: FormInputEvent<InputEvent>
	wheel: FormInputEvent<WheelEvent>
}
