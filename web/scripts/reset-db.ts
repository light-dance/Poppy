#!/usr/bin/env bun
/**
 * Deletes the local SQLite database and reapplies migrations from scratch.
 */

import { dirname, isAbsolute, join } from 'path'
import { mkdir, unlink } from 'fs/promises'

const defaultDbUrl = './db/data.sqlite'
const dbUrl = process.env.DB_URL ?? defaultDbUrl

function resolveDbPath(url: string) {
	if (url === ':memory:' || url.includes('://')) {
		throw new Error(`Refusing to reset non-file SQLite database: ${url}`)
	}

	return isAbsolute(url) ? url : join(process.cwd(), url)
}

async function removeIfExists(path: string) {
	try {
		await unlink(path)
		console.log(`  removed ${path}`)
	} catch (error) {
		if (error instanceof Error && 'code' in error && error.code === 'ENOENT') {
			return
		}

		throw error
	}
}

async function runMigrations() {
	const proc = Bun.spawn(['bunx', '--bun', 'drizzle-kit', 'migrate'], {
		env: {
			...process.env,
			DB_URL: dbUrl
		},
		stdout: 'inherit',
		stderr: 'inherit'
	})

	const exitCode = await proc.exited

	if (exitCode !== 0) {
		throw new Error(`drizzle-kit migrate failed with exit code ${exitCode}`)
	}
}

async function main() {
	const dbPath = resolveDbPath(dbUrl)

	await mkdir(dirname(dbPath), { recursive: true })

	console.log(`Resetting SQLite database at ${dbPath}`)

	await removeIfExists(dbPath)
	await removeIfExists(`${dbPath}-wal`)
	await removeIfExists(`${dbPath}-shm`)

	await runMigrations()

	console.log('\x1b[32m✓ Database reset complete\x1b[0m')
}

main().catch((error) => {
	console.error('\x1b[31m✗ Database reset failed:\x1b[0m', error.message)
	process.exit(1)
})
