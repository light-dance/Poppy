<script lang="ts">
	import { onMount, tick } from 'svelte'
	import { startLoginPasskey, verifyLoginPasskey } from '$remotes/auth/authenticate.remote'
	import { startAuthentication } from '@simplewebauthn/browser'
	import { handleLoginSuccess } from './login-user'

	async function tryLoginPasskey() {
		try {
			const optionsResult = await startLoginPasskey({ identifier: undefined }).run()

			const authenticationResponse = await startAuthentication({
				optionsJSON: optionsResult.options
			})

			const result = await verifyLoginPasskey({ attestation: authenticationResponse })

			if (result.success && result.redirectUrl) {
				handleLoginSuccess(result.redirectUrl)
			}
		} catch (e) {
			console.error(e)
		}
	}

	onMount(async () => {
		await tick()
		await tryLoginPasskey()
	})
</script>
