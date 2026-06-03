<script lang="ts">
	import { onMount } from 'svelte'

	import PasskeyButton from '$ui/auth/passkey-button.svelte'
	import CodeInput from '$ui/auth/code-input.svelte'
	import { startReauth } from '$remotes/auth/authenticate.remote'

	type Props = {
		autoStart?: boolean
		start?: (() => void) | null
		suppressRedirect?: boolean
		onSuccess?: () => void
		onCancel?: () => void
	}
	let {
		autoStart = true,
		start = $bindable(null),
		suppressRedirect = false,
		onSuccess,
		onCancel
	}: Props = $props()

	const localTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone

	let hasBeenStarted = $state(false)
	let loading = $state(false)
	let requireReauth = $state(false)

	let identifier = $state('')
	let passkeyAvailable = $state(false)
	let codeSent = $state(false)

	// Initialize reauth options when dialog opens
	onMount(() => {
		if (autoStart) {
			startIfNeeded()
		}
	})

	start = () => {
		startIfNeeded()
	}

	function startIfNeeded() {
		if (hasBeenStarted) return

		hasBeenStarted = true
		requestStartReauth()
	}

	async function requestStartReauth() {
		loading = true
		try {
			const result = await startReauth({ timezone: localTimezone }).run()

			if (result.recentAuth) {
				requireReauth = false
				onSuccess?.()
			} else {
				requireReauth = true

				identifier = result.identifier
				passkeyAvailable = result.passkeyAvailable
				codeSent = result.codeSent
			}
			loading = false
		} catch (e) {
			console.error('Failed to start reauth', e)
			onCancel?.()
		}
	}
</script>

<div class="flex w-full flex-col gap-5 pt-10">
	{#if !loading && requireReauth}
		<div data-dark class="group/reauth flex w-full flex-col items-center gap-7">
			{#if passkeyAvailable}
				<PasskeyButton {identifier} auto={true} reauth={suppressRedirect} {onSuccess} />
			{/if}

			<div class="flex w-full flex-col items-center gap-1">
				<CodeInput
					{codeSent}
					{identifier}
					timezone={localTimezone}
					reauth={suppressRedirect}
					dark={true}
					{onSuccess}
				/>
			</div>
		</div>
	{/if}
</div>
