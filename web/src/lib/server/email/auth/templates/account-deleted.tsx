import * as React from 'react'
import { Body, Preview, Container, Head, Heading, Html, Text, Tailwind, Section } from 'react-email'

type Options = {
	email: string
}

const AccountDeleted = ({ email }: Options) => {
	return (
		<Html>
			<Preview>Your account has been successfully deleted {email}</Preview>
			<Tailwind>
				<Head>
					<meta name="color-scheme" content="light dark" />
					<meta name="supported-color-schemes" content="light dark" />
				</Head>
				<Body className="bg-white font-sans dark:bg-neutral-900">
					<Container className="w-full max-w-none bg-white pt-[50px] pb-[40px] dark:bg-neutral-900">
						<Section className="mx-auto max-w-[430px] px-1">
							<Heading className="m-0 pb-2 text-left text-[19px] font-[590] tracking-[-0.01em] text-neutral-800 dark:text-white">
								Your account has been deleted
							</Heading>

							<Text className="m-0 mb-[32px] text-left text-[16px] tracking-[-0.01em] text-neutral-500 dark:text-neutral-400">
								Your account (
								<span className="text-neutral-700 dark:text-neutral-300">{email}</span>) has been
								succesfully deleted
							</Text>
						</Section>
					</Container>
				</Body>
			</Tailwind>
		</Html>
	)
}

export default AccountDeleted

AccountDeleted.PreviewProps = {
	email: 'john@apple.com'
} as Options
