import type { CreateEmailOptions } from 'resend'
import { Resend } from 'resend'

import { env } from '$env/dynamic/private'
import { err, ok, type StructuredResult } from '$utils/structured-result'

const IS_DEV = env.NODE_ENV === 'development'
const SEND_IN_DEV = false // Set true to override and send emails in dev

const resend = new Resend(env.RESEND_AUTH)

type SendEmailOptions = Omit<CreateEmailOptions, 'from'> & {
	from?: CreateEmailOptions['from']
}

/**
 * Sends a transactional email through Resend with a default sender.
 * @param options Email payload fields accepted by Resend. `from` is optional and defaults to `SEND_FROM`.
 * @param devMessage Message logged when email sending is suppressed during local development.
 * @returns Structured response with the sent email id when available.
 * @example
 * await sendEmail({ to: 'user@example.com', subject: 'Welcome', react: Template() }, 'Sent welcome')
 */
export async function sendEmail(options: SendEmailOptions, devMessage: string | undefined | null) {
	// Apply module-level defaults, then allow callers to override specific fields.
	const emailOptions = { from: env.RESEND_FROM, ...options } as CreateEmailOptions

	// Skip external sends in development unless explicitly overridden above.
	if (IS_DEV && !SEND_IN_DEV) {
		console.log(devMessage || 'Email suppressed in dev without console message')
		return ok({ id: 'dev-simulated-send' })
	}

	// Call Resend send
	const { error, data } = await resend.emails.send(emailOptions)

	if (error) {
		console.log(error)
		return err(error)
	}

	return ok({ id: data?.id })
}

export type EmailSendResponse = StructuredResult<{ id: string | undefined }, unknown>
