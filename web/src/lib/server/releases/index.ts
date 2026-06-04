import { error } from '@sveltejs/kit'
import { desc, eq } from 'drizzle-orm'

import { db } from '$lib/server/db'
import { releases } from '$lib/server/db/schema'

export type ReleaseNotes = {
	version: string
	build: number
	title: string
	changelog: string
	publishedAt: string
	publishedDate: string
}

function formatReleaseDate(date: Date) {
	return new Intl.DateTimeFormat('en', {
		month: 'long',
		day: 'numeric',
		year: 'numeric'
	}).format(date)
}

function toReleaseNotes(release: typeof releases.$inferSelect): ReleaseNotes {
	return {
		version: release.version,
		build: release.build,
		title: release.title ?? `Version ${release.version}`,
		changelog: release.changelog,
		publishedAt: release.publishedAt.toISOString(),
		publishedDate: formatReleaseDate(release.publishedAt)
	}
}

/**
 * Checks whether a string matches the app release version format.
 *
 * @param version - The version string to test.
 * @returns Whether the version matches `number.number.number`.
 */
function isVersion(version: string) {
	return /^\d+\.\d+\.\d+$/.test(version)
}

/**
 * Validates a requested app version in `0.0.0` form.
 *
 * @param version - The requested version string.
 * @returns The original version string when it matches `number.number.number`.
 * Throws a 404 when the version string does not match that shape.
 */
export function validateVersion(version: string): string {
	if (isVersion(version)) {
		return version
	}

	throw error(404, 'Version Does Not Exist')
}

/**
 * Validates a requested download format and returns the narrowed format type.
 *
 * @param format - The requested download format.
 * @returns The requested format narrowed to a supported download format.
 * Throws a 404 when the format is not supported.
 */
export function validateFormat(format: string): 'dmg' | 'zip' {
	if (format === 'dmg' || format === 'zip') {
		return format
	}

	throw error(404, 'Download URL Invalid')
}

/**
 * Resolves the newest published release version from the database.
 *
 * @returns The version string for the newest release.
 * @throws A 404 response when no release exists.
 */
async function getLatestVersion() {
	// Get newest release from db by published at datetime
	const [latestRelease] = await db
		.select({ version: releases.version })
		.from(releases)
		.orderBy(desc(releases.publishedAt), desc(releases.updatedAt))
		.limit(1)

	// Otherwise throw
	if (!latestRelease) {
		console.error('Latest version cannot be found')
		throw error(404, 'Something Went Wrong')
	}

	return latestRelease.version
}

/**
 * Lists published releases newest-first for changelog and appcast surfaces.
 */
export async function listReleaseNotes() {
	const rows = await db
		.select()
		.from(releases)
		.orderBy(desc(releases.publishedAt), desc(releases.updatedAt))

	return rows.map(toReleaseNotes)
}

/**
 * Resolves a single release by marketing version.
 */
export async function getReleaseNotes(version: string) {
	const [release] = await db.select().from(releases).where(eq(releases.version, version)).limit(1)

	if (!release) {
		throw error(404, 'Release Not Found')
	}

	return toReleaseNotes(release)
}

/**
 * Resolves the storage key for a requested release asset.
 *
 * @param options - The requested download target.
 * @param options.version - A concrete version string or `latest`.
 * @param options.format - The requested asset format.
 * @returns The public storage key for the requested release asset.
 */
export async function resolveDownload({
	version,
	format
}: {
	version: string
	format: 'dmg' | 'zip'
}) {
	let resolvedVersion: string

	if (version === 'latest') {
		resolvedVersion = await getLatestVersion()
	} else {
		resolvedVersion = version
	}

	return `download/s3/releases/${resolvedVersion}/Poppy-${resolvedVersion}.${format}`
}
