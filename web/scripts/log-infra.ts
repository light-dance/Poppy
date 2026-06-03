#!/usr/bin/env bun

/**
 * Creates a new infra change entry under ./infra/changelog using:
 * YYYYMMDDHHmmss_description/change.md
 */

import { mkdir } from 'node:fs/promises'
import { join } from 'node:path'
import { createInterface } from 'node:readline/promises'
import { stdin as input, stdout as output } from 'node:process'

const ANSI_RESET = '\x1b[0m'
const ANSI_BOLD = '\x1b[1m'
const ANSI_GRAY = '\x1b[90m'
const ANSI_GREEN = '\x1b[32m'

function styledPrompt(label: string): string {
	return `${ANSI_GRAY}${ANSI_BOLD}${label}:${ANSI_RESET} `
}

function usage() {
	console.log('Interactive: bun run update:infra')
	console.log(
		'Non-interactive: bun run update:infra "<title>" [--description "<text>"] [--service "<name>"]'
	)
	console.log('Example: bun run update:infra "add redis eviction policy" --service "redis"')
}

function pad(value: number): string {
	return String(value).padStart(2, '0')
}

function timestamp(date = new Date()): string {
	const year = date.getUTCFullYear()
	const month = pad(date.getUTCMonth() + 1)
	const day = pad(date.getUTCDate())
	const hour = pad(date.getUTCHours())
	const minute = pad(date.getUTCMinutes())
	const second = pad(date.getUTCSeconds())
	return `${year}${month}${day}${hour}${minute}${second}`
}

function slugify(value: string): string {
	return value
		.toLowerCase()
		.replace(/[^a-z0-9]+/g, '_')
		.replace(/^_+|_+$/g, '')
}

type ParsedArgs = {
	title: string
	description: string
	service: string
}

function parseArgs(args: string[]): ParsedArgs | null {
	let description: string | undefined
	let service: string | undefined
	const titleParts: string[] = []

	for (let i = 0; i < args.length; i++) {
		const arg = args[i]

		if (arg === '--help' || arg === '-h') {
			usage()
			process.exit(0)
		}

		if (arg === '--description') {
			if (i + 1 >= args.length) {
				console.error('Missing value for --description.')
				return null
			}
			description = args[++i]
			continue
		}
		if (arg.startsWith('--description=')) {
			description = arg.slice('--description='.length)
			continue
		}

		if (arg === '--service') {
			if (i + 1 >= args.length) {
				console.error('Missing value for --service.')
				return null
			}
			service = args[++i]
			continue
		}
		if (arg.startsWith('--service=')) {
			service = arg.slice('--service='.length)
			continue
		}

		if (arg.startsWith('--')) {
			console.error(`Unknown option: ${arg}`)
			return null
		}

		titleParts.push(arg)
	}

	const title = titleParts.join(' ').trim()
	if (!title) {
		return null
	}

	return {
		title,
		description: description?.trim() ?? '',
		service: service?.trim() ?? ''
	}
}

async function promptInteractive(): Promise<ParsedArgs | null> {
	if (!input.isTTY || !output.isTTY) {
		console.error(
			'Interactive mode requires a TTY. Pass a title argument for non-interactive mode.'
		)
		return null
	}

	const rl = createInterface({ input, output })
	try {
		const title = (await rl.question(styledPrompt('Title'))).trim()
		if (!title) {
			console.error('Title is required.')
			return null
		}

		const description = (await rl.question(styledPrompt('Description (optional)'))).trim()
		const serviceInput = (await rl.question(styledPrompt('Service (optional)'))).trim()

		return {
			title,
			description,
			service: serviceInput
		}
	} finally {
		rl.close()
	}
}

function yamlString(value: string): string {
	return `'${value.replace(/'/g, "''")}'`
}

async function main() {
	const args = process.argv.slice(2)

	if (args.includes('--help') || args.includes('-h')) {
		usage()
		process.exit(0)
	}

	const parsed = args.length === 0 ? await promptInteractive() : parseArgs(args)
	if (!parsed) {
		usage()
		process.exit(1)
	}
	const { title, description, service } = parsed

	const slug = slugify(title)
	if (!slug) {
		console.error('Title must include at least one letter or number.')
		process.exit(1)
	}

	const now = new Date()
	const folderName = `${timestamp(now)}_${slug}`
	const changelogRoot = join(process.cwd(), 'infra', 'changelog')
	const entryDir = join(changelogRoot, folderName)
	const changePath = join(entryDir, 'change.md')

	await mkdir(changelogRoot, { recursive: true })
	await mkdir(entryDir)

	const createdAt = now.toISOString()
	const frontmatter = [
		'---',
		`created: ${yamlString(createdAt)}`,
		`title: ${yamlString(title)}`,
		`description: ${yamlString(description)}`,
		`service: ${yamlString(service)}`,
		'---'
	].join('\n')

	const fileContent = `${frontmatter}

## Instructions

-

## Explanation

-
`

	await Bun.write(changePath, fileContent)

	console.log(`${ANSI_GREEN}Created infra/changelog/${folderName}/change.md${ANSI_RESET}`)
}

main().catch((err) => {
	if (err && typeof err === 'object' && 'code' in err && err.code === 'EEXIST') {
		console.error('Entry already exists. Run the command again to generate a new timestamp.')
		process.exit(1)
	}

	console.error('Failed to create infra entry:', err)
	process.exit(1)
})
