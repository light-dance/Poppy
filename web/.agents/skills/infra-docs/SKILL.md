---
name: infra-docs
description: Inspect and maintain the app's infrastructure records, including current-state docs for domains, DNS, hosting, environments, provider accounts, and other non-code systems the app relies on.
---

# Purpose

Use this skill when the user asks you to update or ask questions about the app's infrastructure: hosting, services, external providers, GitHub settings, or click-ops changes.

The infra docs are the declarative source of truth for dashboard and click-ops setup that is not fully represented in code. They should let a team understand and recover external infrastructure without relying on memory.

## Infrastructure Documentation Files

```txt
infra/
  docs/
    +[critical-provider-or-platform].md
    [secondary-or-tool-provider].md
  TODOS.md
  changelog/
    ...
```
Examples: `infra/docs/+cloudflare.md` for critical Cloudflare DNS, TLS, edge, and registration settings; `infra/docs/+railway.md` for critical hosting; `infra/docs/posthog.md` for a secondary analytics service.

Current-state docs should be organized by service provider or platform, not by generic area. Put DNS records in the provider doc where they are managed, such as Cloudflare, rather than a generic `dns.md`.

Prefix critical infrastructure docs with `+`. Critical services are directly tied to hosting, delivering, deploying, or core app operation. Do not use an index file to define tiers; the filename convention carries the critical marker.

Use plain filenames for secondary services and team tools. Incomplete docs should be marked inside the file as stubs and tracked in `infra/TODOS.md`, not with a filename prefix.

Only edit files under `infra/docs/` and `infra/TODOS.md`. `infra/changelog/` is read-only for this skill. Use it as historical context when investigating current setup, but do not create, edit, or move changelog entries directly.

## Workflow

Use the smallest workflow that answers the request accurately:

1. List `infra/docs/` to identify the relevant service/provider docs. Critical docs are prefixed with `+`.
2. Read `infra/TODOS.md` when it exists so outstanding infra work is considered.
3. Read the relevant service/provider docs before answering or editing.
4. If the current docs are incomplete, inspect targeted context that could verify the setup:
   - `.env.example` for environment variable names
   - `.github/` for GitHub Actions, repository automation, and deploy hooks
   - `package.json` and `scripts/` for operational commands
   - `infra/changelog/` for historical context
5. Before editing docs for external/click-ops infrastructure, pause and ask the user for enough missing details to make the docs operationally useful. Do not create placeholder-heavy docs from a high-level summary when the setup depends on provider console state.
6. For doc updates, edit only the affected files under `infra/docs/` and `infra/TODOS.md`.
7. Add cross-links only when they make future investigation easier.
8. If the user made an actual infrastructure change, remind them to run the `update:infra` script to log the change. Do not write changelog entries by hand.
9. In the final response, summarize the updated docs areas, TODO changes, and any remaining unknowns.

Prefer small, factual updates over broad rewrites.

## Discovery Before Editing

For external systems that are not fully represented in code, treat the goal as recovery-grade documentation: if the provider or repository disappeared from memory tomorrow, the docs should describe the current state well enough to inspect, verify, and rebuild it.

Before editing, gather the important unknowns. Ask concise grouped questions and wait for answers when the current information is too thin. Continue asking follow-up questions until the known setup is specific enough to document with confidence.

Do not document secrets. It is OK to document account labels, provider teams, non-secret identifiers, record names, settings, where secrets are stored, and how to regenerate or rotate them.

For domain and DNS documentation, ask about:

- Domain name, registrar, renewal/auto-renew status, registrar account/team, and where login access is managed
- Authoritative nameservers and how the registrar delegates to the DNS provider
- DNS provider account/team, zone name, plan/tier, and access/ownership model
- Complete DNS record inventory: name, type, value/target, TTL, proxied/DNS-only status, priority, purpose, and owning service
- Cloudflare zone configuration that matters operationally: proxy status, SSL/TLS mode, redirects, page rules, WAF/security rules, DDoS settings, cache rules, workers, load balancing, tunnels, access policies, email routing, analytics/logging, and any other enabled Cloudflare products
- Services supported by DNS records, such as the app host, email sending/receiving, authentication callbacks, analytics/reverse proxies, storage/CDN, verification records, and provider-specific validation records
- Recovery procedure: where to log in, what to verify first, how to restore nameserver delegation, how to recreate critical records, and how to validate production traffic and email afterward

For other infrastructure areas, ask equivalent recovery-grade questions: provider account/team, environments, resources, configuration, dependencies, operational settings, secrets locations, verification steps, and rebuild procedure.

## Current-State Docs

Use `infra/docs/` for facts that should remain true until the infrastructure changes.

Examples:

- Namecheap domain registration and renewal settings
- Cloudflare DNS records, edge settings, TLS, redirects, and zone security
- Railway projects, environments, services, buckets, databases, and plugins
- GitHub repo settings, actions, secrets, deploy hooks, and branch rules
- Purelymail, Resend, PostHog, Axiom, Autumn, and other external provider setup
- operational runbooks

Do not put historical narrative in current-state docs, only represent what is the current state.

## Service Doc Structure

Service docs should be named for the provider or platform. Prefix critical infrastructure with `+`, such as `+cloudflare.md`, `+railway.md`, `+resend.md`, `+autumn.md`, or `+github.md`. Use plain names for secondary services and team tools, such as `posthog.md`, `axiom.md`, or `cubic.md`.

Use this high-level structure:

```md
# Provider Name

Short description of the service's role and purpose.

## Access

## Security

## Contents

## Provider-Specific Section

## Recovery
```

Start with a short paragraph describing the service's role in delivering, operating, or maintaining the app. Do not list every setting up front.

`Access` should be compact text, not a table by default:

```md
**Ownership:** ...

**Login:** ...

_Short access note if needed_
```

Do not document passwords, API keys, backup codes, or secret values.

`Security` should read like a terse threat model:

- One short risk-orientation sentence
- `Exposure`: what a bad actor could do with access
- `Vulnerabilities`: why the service/account is fragile
- `Mitigations`: controls currently reducing risk

Keep security bullets dense and declarative. Avoid tutorial prose, redundant labels, and self-evident statements.

`Contents` should be a linked table of contents, with short italic descriptors when useful.

Adapt lower provider-specific sections to the service. For example, Cloudflare may use `Domain`, `Redirect Rules`, and `DNS Records`; Railway may use `Projects`, `Environments`, and `Services`; GitHub may use `Repository`, `Actions`, `Branch Protection`, and `Secrets`.

For exact machine/recovery data that is too noisy for markdown, add a structured adjacent file such as `usespring.app.dns.yaml` and link to it. Keep markdown readable while preserving exact recovery values.

For incomplete service docs, mark them clearly as stubs in the document body and keep a matching item in `infra/TODOS.md`. Do not create or maintain `infra/docs/index.md`.

## TODOs

Use `infra/TODOS.md` for known infrastructure follow-ups, grouped by service/provider. Keep TODOs short and actionable.

Update `infra/TODOS.md` when:

- The user identifies future infra work while documenting current state
- A TODO is completed and should be removed
- A TODO changes shape, such as replacing "change billing card" with "transfer registration to Cloudflare Registrar"

Keep TODOs in sync with stub docs. If a service doc is marked as a stub, make sure `infra/TODOS.md` has a matching documentation task unless the stub itself is intentionally enough for now.

## Documentation Style

Keep docs operational, factual, declarative, and easy to scan. Write like an experienced infrastructure team documenting current state, not like a tutorial.

Prefer terse fragments over explanatory prose when they carry the same information. Every sentence should add state, risk, or recovery value.

Use tables where they improve scanning:

```md
| Name | Type | Location | Purpose | Notes |
| --- | --- | --- | --- | --- |
```

Prefer bullets for short setup notes. Avoid redundancy, obvious provider self-references, and history unless the date is part of current state.

Use exact provider names, environment names, service names, variable names, domains, and record names. Prompt the user if you need more information to create a good doc.

## Prompting The User

Ask the user for missing details when needed to make the docs accurate. You may also use the repo to find answers when applicable.

Ask concise, targeted questions. Group related unknowns together. Ask with a text prompt, do not use the harness' interactive multiple choice tool.

Prefer asking before editing over writing docs with many unknowns. If the user's initial description is high-level, ask for provider-console details first. Only proceed to edit once the docs can capture the meaningful current state, or once the user explicitly says to document partial knowledge with named unknowns.

Example questions:

- Did this require updating secrets variables? If so, where did you go to get those?
- Which environment does this effect?
- What were the values you set for the DNS update? Where did you get those values from?

## Runbooks

In addition to documenting providers and services we depend on, you may also document "runbooks". Runbooks are to track operational procedures that someone may need during maintenance or incidents.

Good runbooks are short, step-based, and include verification steps.

## Completion Checklist

Before finishing an infra docs update:

- Current-state docs reflect the latest known setup.
- Docs are organized by service/provider or platform.
- Critical service docs use the `+provider.md` filename convention.
- Service docs start with a short role/purpose description, then `Access`, `Security`, and `Contents`.
- Security reads as a terse threat model with exposure, vulnerabilities, and mitigations.
- Incomplete service docs are marked as stubs in the file body and represented in `infra/TODOS.md`.
- `infra/TODOS.md` reflects remaining follow-ups and completed items have been removed.
- Related files are cross-linked where useful.
- Secret values are not documented.
- Unknowns have been eliminated/reduced through user questions or repo/provider evidence before editing.
- For external/click-ops systems, the docs are specific enough to help recover the setup if it breaks.
- If actual infrastructure changed, the final response reminds the user to run `update:infra` to log it.
- The final response lists updated docs, TODO changes, and remaining unknowns.
