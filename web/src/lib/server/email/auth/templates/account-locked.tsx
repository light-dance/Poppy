import * as React from 'react'
import { Body, Preview, Container, Head, Html, Text, Tailwind, Section } from 'react-email'

import type { LockType } from '$lib/server/auth/schema'

import { HeaderGroup } from '../components/header-group'

type Options = {
	email: string
	lockType: LockType
}

function getLockCopy(lockType: LockType) {
	if (lockType === 'bot') {
		return {
			label: 'Flagged as bot',
			description: 'Your account was flagged due to activity that appeared automated',
			whatToDo: 'Please get in touch to verify your identity and request account recovery.'
		}
	}

	if (lockType === 'security') {
		return {
			label: 'Locked for security concern',
			description: 'Your account was locked due to unusual activity that raised a security concern',
			whatToDo: 'Please get in touch to verify your identity and request account recovery.'
		}
	}

	return {
		label: 'Banned for behavior',
		description: 'Your account was banned due to behavior that violated our policies',
		whatToDo: 'You may be able to resolve by contacting us and appealing.'
	}
}

const AccountLocked = ({ email, lockType }: Options) => {
	const lockCopy = getLockCopy(lockType)

	return (
		<Html>
			<Preview>Your account has been locked ({lockCopy.label.toLowerCase()}).</Preview>
			<Tailwind>
				<Head>
					<meta name="color-scheme" content="light dark" />
					<meta name="supported-color-schemes" content="light dark" />
					<style>
						{`
							/* Keep auto-detected links from taking client default blue styles. */
							a[x-apple-data-detectors],
							.x-gmail-data-detectors,
							.x-gmail-data-detectors *,
							u + .email-body a {
								color: inherit !important;
								text-decoration: none !important;
								font-size: inherit !important;
								font-family: inherit !important;
								font-weight: inherit !important;
								line-height: inherit !important;
							}

							/* Ensure detected links inside the email pill keep white text. */
							.email-pill a,
							.email-pill a:visited,
							.email-pill a:hover,
							.email-pill a:active {
								color: #f5f5f5 !important;
								text-decoration: none !important;
							}
						`}
					</style>
				</Head>
				<Body className="email-body bg-white font-sans dark:bg-neutral-900">
					<Container className="w-full max-w-none bg-white pt-[50px] pb-10 dark:bg-neutral-900">
						<Section className="mx-auto max-w-[430px] px-1">
							<HeaderGroup
								headingText="Your account has been locked"
								descriptiveText={lockCopy.description}
							/>

							<Section className="mt-2 mb-2 w-full">
								<Text className="email-pill m-0 inline-block rounded-full border-2 border-black bg-black px-5 py-2 text-left tracking-[-0.01em] text-neutral-100">
									{email}
								</Text>
							</Section>

							<Section className="mb-12 w-full">
								<Text className="m-0 inline-block rounded-full border-2 border-neutral-300 px-5 py-2 text-left font-medium tracking-[-0.01em] text-neutral-900 dark:border-neutral-600 dark:text-neutral-100">
									{lockCopy.label}
								</Text>
							</Section>

							<Section className="mt-5">
								<Text className="m-0 mb-2 text-left text-[14px] font-semibold tracking-[-0.01em] text-black dark:text-white">
									What this means
								</Text>
								<Text className="m-0 text-left text-[16px] tracking-[-0.01em] text-neutral-800 dark:text-neutral-200">
									You will not be able to use your account until this lock is resolved. Your data
									will not be deleted and you will not be billed.
								</Text>
							</Section>

							<Section className="mt-5">
								<Text className="m-0 mb-2 text-left text-[14px] font-semibold tracking-[-0.01em] text-blue-600 dark:text-blue-400">
									What to do
								</Text>
								<Text className="m-0 text-left text-[16px] tracking-[-0.01em] text-neutral-500 dark:text-neutral-400">
									Support is here to help. {lockCopy.whatToDo}
								</Text>
							</Section>
						</Section>
					</Container>
				</Body>
			</Tailwind>
		</Html>
	)
}

export default AccountLocked

AccountLocked.PreviewProps = {
	email: 'john@apple.com',
	lockType: 'security'
} as Options
