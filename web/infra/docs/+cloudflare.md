# Cloudflare

Cloudflare is the front door for `usespring.app`: domain ownership, DNS, edge proxying, CDN behavior, and DDoS protection. Web traffic routes from Cloudflare to Railway; email DNS routes to Purelymail and Resend.

## Access

**Ownership:** `jake@notnotjake.com` personal account

**Login:** `jake@notnotjake.com`

_Single-owner access: Jake only_

## Security

Cloudflare controls the domain and the DNS layer that points users and email providers at the rest of the stack. Main risks: account compromise, account loss, provider suspension, and destructive DNS changes.

**Exposure:**

- Full domain and DNS control for `usespring.app`
- Traffic hijack, production outage, email disruption, or domain-backed impersonation through DNS changes
- App routing, TLS/HTTPS, redirects, and email DNS mutable outside code
- Workers and paid products available from the account

**Vulnerabilities:**

- Personal account susceptible to compromise and lockout
- Account susceptible to provider suspension
- Single-owner recovery path
- Registrar and DNS concentrated in one provider

**Mitigations:**

- Passkey and TOTP enabled; backup codes stored in 1Password
- DNSSEC enabled for `usespring.app`
- Always Use HTTPS enabled

## Contents

- [Domain](#domain) _Registration, zone, TLS, proxy, and DNSSEC settings_
- [Redirect Rules](#redirect-rules) _`www` to apex redirect behavior_
- [DNS Records](#dns-records) _Railway routing plus Purelymail and Resend email records_
- [Recovery](#recovery) _Checks for restoring or validating the Cloudflare setup_

## Domain

**Registration**

| Domain | Account | Renewal | Billing |
| --- | --- | --- | --- |
| `usespring.app` | `jake@notnotjake.com` | July 1, 2027 | Business card |

**Zone settings**

- Plan: Free
- SSL/TLS mode: Full
- Always Use HTTPS: enabled
- DNSSEC: enabled
- Cloudflare Email Routing is configured but disabled

No known WAF rules, cache rules, workers, tunnels, access policies, load balancing, AI Crawl Control, or custom Cloudflare products beyond DNS, proxied records, disabled Email Routing, and the redirect below.

## Redirect Rules

| Name                                   | Source                        | Target                       | Status | Purpose                                   |
| -------------------------------------- | ----------------------------- | ---------------------------- | ------ | ----------------------------------------- |
| `Redirect from WWW to Root [Template]` | `https://www.usespring.app/*` | `https://usespring.app/${1}` | `301`  | Redirect `www` traffic to the apex domain |

## DNS Records

Readable service map below. Exact DNS values live in [usespring.app.dns.yaml](./usespring.app.dns.yaml) for recovery/reference.

**Railway**

| Type | Name | Target / Value | Proxy | Note |
| --- | --- | --- | --- | --- |
| `CNAME` | `*` | `w4y61qrx.up.railway.app` | Proxied | Production app |
| `CNAME` | `next` | `gsurgbx6.up.railway.app` | Proxied | Next environment |
| `TXT` | `_railway-verify.next` | `railway-verify=...` | DNS-only | Domain verification |

**Cloudflare**

| Type | Name | Target / Value | Proxy | Note |
| --- | --- | --- | --- | --- |
| `CNAME` | `www` | `usespring.app` | Proxied | Supports `www` to apex redirect |

**Purelymail**

| Type | Name | Target / Value | Proxy | Note |
| --- | --- | --- | --- | --- |
| `MX` | `*` | `50 mailserver.purelymail.com` | DNS-only | Mailbox hosting |
| `TXT` | `*` | `purelymail_ownership_proof=...` | DNS-only | Ownership proof |
| `TXT` | `*` | `v=spf1 include:_spf.purelymail.com ~all` | DNS-only | SPF |
| `CNAME` | `_dmarc` | `dmarcroot.purelymail.com` | DNS-only | DMARC |
| `CNAME` | `purelymail1._domainkey` | `key1.dkimroot.purelymail.com` | DNS-only | DKIM |
| `CNAME` | `purelymail2._domainkey` | `key2.dkimroot.purelymail.com` | DNS-only | DKIM |
| `CNAME` | `purelymail3._domainkey` | `key3.dkimroot.purelymail.com` | DNS-only | DKIM |

**Resend**

| Type | Name | Target / Value | Proxy | Note |
| --- | --- | --- | --- | --- |
| `MX` | `send.resend` | `10 feedback-smtp.us-east-1.amazonses.com` | DNS-only | Bounce/feedback |
| `TXT` | `send.resend` | `v=spf1 include:amazonses.com ~all` | DNS-only | SPF |
| `TXT` | `resend._domainkey.resend` | `p=...` | DNS-only | DKIM |

## Recovery

1. Confirm `usespring.app` is active in Cloudflare Registrar
2. Confirm the `usespring.app` DNS zone is active
3. Confirm DNSSEC is enabled
4. Confirm SSL/TLS mode is Full and Always Use HTTPS is enabled
5. Confirm the Railway CNAME records for `usespring.app` and `next.usespring.app` exist and are proxied
6. Confirm the `www` redirect rule points `https://www.usespring.app/*` to `https://usespring.app/${1}`
7. Confirm Purelymail DNS records are present for mailbox hosting
8. Confirm Resend DNS records are present for app email sending
