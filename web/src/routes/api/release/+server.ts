import { RELEASE_API_TOKEN } from '$env/static/private'
import { error, json } from '@sveltejs/kit'
import * as v from 'valibot'
import type { RequestHandler } from './$types'

import { db } from '$lib/server/db'
import { releases } from '$lib/server/db/schema'

const releasePayloadSchema = v.object({
	version: v.pipe(
		v.string('version is required'),
		v.trim(),
		v.regex(/^\d+\.\d+\.\d+$/, 'version must use number.number.number format')
	),
	build: v.pipe(
		v.union([v.number(), v.string()], 'build is required'),
		v.transform((value) => Number(value)),
		v.integer('build must be an integer'),
		v.minValue(1, 'build must be at least 1')
	),
	title: v.optional(
		v.pipe(
			v.string(),
			v.trim(),
			v.transform((value) => value || null)
		)
	),
	changelog: v.pipe(
		v.string('changelog is required'),
		v.check((value) => value.trim() !== '', 'changelog is required')
	),
	sparkleZipLength: v.optional(
		v.pipe(
			v.union([v.number(), v.string()]),
			v.transform((value) => Number(value)),
			v.integer('sparkleZipLength must be an integer'),
			v.minValue(1, 'sparkleZipLength must be at least 1')
		)
	),
	sparkleZipSignature: v.optional(
		v.pipe(
			v.string(),
			v.trim(),
			v.transform((value) => value || null)
		)
	)
})

/**
 * Parses the release request body as JSON and validates it against the release payload schema.
 */
async function parseRequest(request: Request) {
	// Try to parse to JSON
	let payload: unknown
	try {
		payload = await request.json()
	} catch {
		throw error(400, 'Request body must be valid JSON')
	}

	const result = v.safeParse(releasePayloadSchema, payload)

	if (!result.success) {
		throw error(400, result.issues[0]?.message ?? 'Request body is invalid')
	}

	return result.output
}

/**
 * Verifies the request token from either the bearer header or x-release-token header.
 */
function authorizeRequest(request: Request) {
	const authorization = request.headers.get('authorization')
	const bearer = authorization?.match(/^Bearer\s+(.+)$/i)
	const token = bearer?.[1] ?? request.headers.get('x-release-token')

	if (RELEASE_API_TOKEN !== token) {
		throw error(401, 'Unauthorized')
	}
}

/**
 * Publishes or updates release metadata for a version after authorization and validation.
 */
export const POST: RequestHandler = async ({ request }) => {
	authorizeRequest(request)

	const release = await parseRequest(request)
	const now = new Date()

	await db
		.insert(releases)
		.values({
			...release,
			publishedAt: now,
			updatedAt: now
		})
		.onConflictDoUpdate({
			target: releases.version,
			set: {
				build: release.build,
				title: release.title,
				changelog: release.changelog,
				sparkleZipLength: release.sparkleZipLength,
				sparkleZipSignature: release.sparkleZipSignature,
				updatedAt: now
			}
		})

	return json({
		success: true,
		release
	})
}
