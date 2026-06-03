import { sendEmail } from '../send'

import PaymentUpcoming from './templates/payment-upcoming'

export async function paymentUpcoming({ email }: { email: string }) {
	const result = await sendEmail(
		{
			to: email,
			subject: 'Test',
			react: PaymentUpcoming()
		},
		`Payment upcoming.`
	)

	if (result.isError) {
		throw Error()
	}

	return
}

export const sendPaymentEmail = {
	paymentUpcoming
}
