# Infrastructure

Infrastructure changes are logged in `infra/changelog/`.

This project is hosted on Railway with three environments:

- `dev`
- `next`
- `prod`

## Dev

- `user-storage` bucket
- `posthog-reverse-proxy` service (Railway template)
- `vars` service (empty service used for variables)

## Next

- `app` service (this SvelteKit project)
- Redis
- Postgres
- `user-content` bucket
- `posthog-reverse-proxy` service (Railway template)

## Prod

- Environment exists
- Service details to be documented

## Shared Integrations

- PostHog
- Axiom
- Resend
- Autumn

## External Tools

- Devin review
- Cubic
