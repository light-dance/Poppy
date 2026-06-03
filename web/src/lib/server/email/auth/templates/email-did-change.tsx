import * as React from 'react'
import { Body, Preview, Container, Head, Html, Text, Tailwind, Section } from 'react-email'

import { HeaderGroup } from '../components/header-group'

type Options = {
	updatedEmail: string
}

const EmailDidChange = ({ updatedEmail }: Options) => {
	return (
		<Html>
			<Preview>Your account's email has been changed to {updatedEmail}</Preview>
			<Tailwind>
				<Head>
					<meta name="color-scheme" content="light dark" />
					<meta name="supported-color-schemes" content="light dark" />
				</Head>
				<Body className="bg-white font-sans dark:bg-neutral-900">
					<Container className="w-full max-w-none bg-white pt-[50px] pb-10 dark:bg-neutral-900">
						<Section className="mx-auto max-w-[430px] px-1">
							<HeaderGroup
								headingText="Your account email has been changed"
								descriptiveText={
									<>
										You can now login to your account using{' '}
										<span className="text-neutral-700 dark:text-neutral-300">{updatedEmail}</span>
									</>
								}
							/>

							<Text className="m-0 mt-8 text-left text-[16px] tracking-[-0.01em] text-neutral-500 dark:text-neutral-400">
								If you did not make this change, please contact support immediately.
							</Text>
						</Section>
					</Container>
				</Body>
			</Tailwind>
		</Html>
	)
}

export default EmailDidChange

EmailDidChange.PreviewProps = {
	updatedEmail: 'john@apple.com'
} as Options
