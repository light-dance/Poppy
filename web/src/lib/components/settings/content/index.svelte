<script lang="ts">
	import { getUser } from '$remotes/auth/user.remote'
	import { getPasskeyCount } from '$remotes/auth/passkey.remote'
	import { getSessionCount } from '$remotes/auth/session.remote'

	import {
		IconUserCircle,
		IconKeyFilled,
		IconDeviceIpadHorizontalPin,
		IconTrashFilled,
		IconCreditCard,
		IconUsers
	} from '@tabler/icons-svelte'
	import AccordionItem from '$ui/settings/components/accordion-item.svelte'
	import DialogItem from '$ui/settings/components/dialog-item.svelte'
	import Section from '$ui/settings/components/section.svelte'
	import Divider from '$ui/settings/components/item-divider.svelte'

	import ProfilePic from './profile/pic.svelte'
	import ProfileName from './profile/name.svelte'

	import Billing from './account/billing.svelte'
	import LoginMethod from './account/login-method.svelte'
	import Passkeys from './account/passkeys.svelte'
	import Sessions from './account/sessions.svelte'
	import DeleteAccount from './account/delete-account.svelte'

	let getUserPromise = $derived(getUser())
	let user = $derived(await getUserPromise)

	let passkeyCountPromise = $derived(getPasskeyCount())
	let passkeyCount = $derived(await passkeyCountPromise)
	let passkeyHint = $derived(
		passkeyCount === 0
			? 'No Passkeys'
			: passkeyCount === 1
				? '1 Passkey'
				: `${passkeyCount} Passkeys`
	)

	let sessionCountPromise = $derived(getSessionCount())
	let sessionCount = $derived(await sessionCountPromise)
	let sessionHint = $derived(
		sessionCount === 1 ? 'Signed in 1 place' : `Signed in ${sessionCount} places`
	)
</script>

<!-- Profile -->
<div class="flex w-full flex-col items-center gap-2.5 pb-5">
	<ProfilePic profilePic={user.profilePic} />
	<ProfileName />
</div>

<!-- Billing and Team -->
<Section title="Billing">
	<AccordionItem
		id="billing"
		icon={IconCreditCard}
		title="Billing"
		hint="Pro Monthly"
		actionButtonText="Manage"
	>
		{#snippet hintSnippet()}
			<!-- <div class="flex gap-2 tracking-tight-sm">
				<p class="font-bold">Pro</p>
				<p>Monthly</p>
			</div> -->

			<div class="flex gap-1.5 rounded-full tracking-tight-md">
				<p class="font-bold text-orange-500">Expired</p>
				<p class="text-white/70">Resubscribe Now</p>
			</div>
		{/snippet}

		{#snippet content()}
			<Billing />
		{/snippet}
	</AccordionItem>

	<Divider />

	<AccordionItem id="team" icon={IconUsers} title="Team" hint="3 Members" actionButtonText="Invite">
		{#snippet content()}
			<p>Next payment: Mar 18, 2026</p>
		{/snippet}
	</AccordionItem>
</Section>

<!-- Account -->
<Section title="Account Settings">
	<DialogItem icon={IconUserCircle} title="Login Method" hint={user.identifier ?? ''} protected>
		{#snippet content({ close })}
			<LoginMethod {close} />
		{/snippet}
	</DialogItem>

	<Divider />

	<AccordionItem
		id="account-passkeys"
		icon={IconKeyFilled}
		title="Passkeys"
		hint={passkeyHint}
		actionButtonText="Add Passkey"
	>
		{#snippet content({ registerAction })}
			<Passkeys {registerAction} />
		{/snippet}
	</AccordionItem>

	<Divider />

	<AccordionItem
		id="account-sessions"
		icon={IconDeviceIpadHorizontalPin}
		title="Sessions"
		hint={sessionHint}
		actionButtonText="Remove All"
	>
		{#snippet content({ registerAction })}
			<Sessions {registerAction} />
		{/snippet}
	</AccordionItem>

	<Divider />

	<DialogItem icon={IconTrashFilled} title="Delete Account" protected>
		{#snippet content()}
			<DeleteAccount />
		{/snippet}
	</DialogItem>
</Section>
