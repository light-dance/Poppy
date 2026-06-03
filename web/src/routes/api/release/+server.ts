import { env } from '$env/dynamic/private'
import { error, json } from '@sveltejs/kit'
import type { RequestHandler } from './$types'

import { db } from '$lib/server/db'
import { releases } from '$lib/server/db/schema'

interface ReleasePayload {
	buildNumber?: unknown
	version?: unknown
	title?: unknown
	changelog?: unknown
}

function readBearerToken(request: Request) {
	const authorization = request.headers.get('authorization')
	const match = authorization?.match(/^Bearer\s+(.+)$/i)

	return match?.[1] ?? request.headers.get('x-release-token')
}

function assertAuthorized(request: Request) {
	if (!env.RELEASE_API_TOKEN) {
		throw error(500, 'RELEASE_API_TOKEN is not configured')
	}

	if (readBearerToken(request) !== env.RELEASE_API_TOKEN) {
		throw error(401, 'Unauthorized')
	}
}

function parseStringField(payload: ReleasePayload, field: 'version' | 'title' | 'changelog') {
	const value = payload[field]

	if (typeof value !== 'string' || value.trim() === '') {
		throw error(400, `${field} is required`)
	}

	return field === 'changelog' ? value : value.trim()
}

function parseBuildNumber(payload: ReleasePayload) {
	const value = payload.buildNumber
	const buildNumber = typeof value === 'string' ? Number(value) : value

	if (typeof buildNumber !== 'number' || !Number.isInteger(buildNumber) || buildNumber < 0) {
		throw error(400, 'buildNumber must be a non-negative integer')
	}

	return buildNumber
}

async function readPayload(request: Request): Promise<ReleasePayload> {
	try {
		return (await request.json()) as ReleasePayload
	} catch {
		throw error(400, 'Request body must be valid JSON')
	}
}

export const POST: RequestHandler = async ({ request }) => {
	assertAuthorized(request)

	const payload = await readPayload(request)
	const buildNumber = parseBuildNumber(payload)
	const version = parseStringField(payload, 'version')
	const title = parseStringField(payload, 'title')
	const changelog = parseStringField(payload, 'changelog')
	const now = new Date()

	await db
		.insert(releases)
		.values({
			buildNumber,
			version,
			title,
			changelog,
			publishedAt: now,
			updatedAt: now
		})
		.onConflictDoUpdate({
			target: releases.buildNumber,
			set: {
				version,
				title,
				changelog,
				updatedAt: now
			}
		})

	return json({
		release: {
			buildNumber,
			version,
			title,
			changelog
		},
		downloads: {
			dmg: `/download/${version}/dmg`,
			zip: `/download/${version}/zip`,
			latestDmg: '/download/latest/dmg',
			latestZip: '/download/latest/zip'
		}
	})
}
