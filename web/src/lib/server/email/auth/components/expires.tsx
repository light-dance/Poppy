import * as React from 'react'
import { Text, Section } from 'react-email'

export const Expires = ({
	maxAgeMins,
	expiresAtString
}: {
	maxAgeMins: number
	expiresAtString: string | false
}) => {
	return (
		<Section>
			<Text className="m-0 text-left text-[14px] leading-5 text-neutral-700 dark:text-neutral-200">
				This login will be available for {maxAgeMins} minutes
			</Text>

			{expiresAtString && (
				<Text className="m-0 text-left text-[14px] text-neutral-500 dark:text-neutral-400">
					Expires at {expiresAtString}
				</Text>
			)}
		</Section>
	)
}
