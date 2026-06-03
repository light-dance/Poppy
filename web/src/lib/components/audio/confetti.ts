import type { SoundDefinition } from '@web-kits/audio'

export const confetti: SoundDefinition = {
	layers: [
		{
			source: { type: 'sine', frequency: 523 },
			envelope: { attack: 0.002, decay: 0.18, sustain: 0.04, release: 0.08 },
			gain: 0.14
		},
		{
			source: { type: 'sine', frequency: 659 },
			envelope: { attack: 0.002, decay: 0.18, sustain: 0.04, release: 0.08 },
			delay: 0.06,
			gain: 0.14
		},
		{
			source: { type: 'sine', frequency: 784 },
			envelope: { attack: 0.002, decay: 0.18, sustain: 0.03, release: 0.08 },
			delay: 0.12,
			gain: 0.12
		},
		{
			source: { type: 'sine', frequency: { start: 1047, end: 1175 } },
			envelope: { attack: 0.002, decay: 0.2, sustain: 0.03, release: 0.1 },
			delay: 0.18,
			gain: 0.1
		}
	]
}
