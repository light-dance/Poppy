import { defineSound, ensureReady, type SoundDefinition } from '@web-kits/audio'
import { confetti, click } from './core'

export async function playAudio(sound: SoundDefinition) {
	await ensureReady()

	const audio = defineSound(sound)

	audio()
}

export async function playConfetti() {
	await playAudio(confetti)
}
export async function playClick() {
	await playAudio(click)
}
