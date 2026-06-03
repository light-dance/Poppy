# email

Transactional email sending using Resend and React Email templates.

## Files

- `send.ts` - Resend client setup, default sender config, and `sendEmail()` function
- `index.ts` - Re-exports all domain send objects

## sendEmail

The core function that wraps the Resend client. Takes two arguments:

1. Resend email options (`to`, `subject`, `react`, optional `from`)
2. A dev message to log to console when emails are suppressed

Returns a `StructuredResult` with `{ isOk, isError, data, error }`.

```typescript
import { sendEmail } from '../send'

const result = await sendEmail(
	{
		to: email,
		subject: 'Hello',
		react: MyTemplate({ name })
	},
	`Dev log: sent hello to ${name}`
)

if (result.isError) {
	throw Error()
}
```

Default sender is configured in `send.ts` via `SEND_FROM` (from `env.SEND_FROM` with fallback).

## Domains Structure

Emails are organized into directories by domain (e.g. `auth/`, `payments/`). Each domain groups related emails together with their own templates, components, and utilities:

```
{domain}/
  templates/     # React Email templates (.tsx)
  components/    # Shared components for this domain
  utils/         # Domain-specific helpers
  index.ts       # Send functions + exported object
```

## Adding a New Domain

1. Create the directory structure: `{domain}/templates/`, `{domain}/components/`, `{domain}/utils/`

2. Create `{domain}/index.ts` with send functions and export object:

```typescript
import { sendEmail } from '../send'
import MyTemplate from './templates/my-template'

export async function welcomeUser({ email, name }: { email: string; name: string }) {
	const result = await sendEmail(
		{
			to: email,
			subject: 'Welcome!',
			react: MyTemplate({ name })
		},
		`Welcome email sent to ${name}` // Dev console message
	)

	if (result.isError) {
		throw Error()
	}
}

export const sendOnboardingEmail = {
	welcomeUser
	// Add more functions here
}
```

3. Re-export from root `index.ts`:

```typescript
export { sendOnboardingEmail } from './onboarding'
```

## Adding a Template

Templates are React Email components. Create in `{domain}/templates/`:

```tsx
import * as React from 'react'
import { Html, Preview, Body, Container, Text, Tailwind } from 'react-email'

type Props = { name: string }

const MyTemplate = ({ name }: Props) => {
	return (
		<Html>
			<Preview>Welcome to the app</Preview>
			<Tailwind>
				<Body>
					<Container>
						<Text>Hello {name}</Text>
					</Container>
				</Body>
			</Tailwind>
		</Html>
	)
}

export default MyTemplate

// For local preview with `bun run dev:emails`
MyTemplate.PreviewProps = { name: 'Jake' } as Props
```

Shared components go in `{domain}/components/`, utilities in `{domain}/utils/`.

## Dev Mode

Emails are suppressed in development. Instead of sending, the second argument to `sendEmail()` is logged to the console - use this to include any relevant info (codes, links, etc.) for local testing.

```typescript
await sendEmail(
	{ to, subject, react: Template() },
	`Login code: ${code}` // Logged to console in dev
)
```

To force sending in dev, override in `send.ts`:

```typescript
const SEND_EMAILS_OVERRIDE: true | null = true
```
