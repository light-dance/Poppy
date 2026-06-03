#!/usr/bin/env bun

type GitResult = {
	success: boolean
	stdout: string
	stderr: string
}

function runGit(args: string[], quiet = false): GitResult {
	const proc = Bun.spawnSync(['git', ...args], {
		stdout: 'pipe',
		stderr: 'pipe'
	})

	const stdout = proc.stdout.toString().trim()
	const stderr = proc.stderr.toString().trim()
	const success = proc.exitCode === 0

	if (!success && !quiet) {
		console.error(`git ${args.join(' ')} failed:`)
		if (stderr) console.error(stderr)
	}

	return { success, stdout, stderr }
}

function escapeAnnotation(value: string): string {
	return value.replace(/%/g, '%25').replace(/\r/g, '%0D').replace(/\n/g, '%0A')
}

function resolveShas(): { baseSha: string; headSha: string } | null {
	const eventName = process.env.EVENT_NAME

	if (eventName === 'pull_request') {
		const baseSha = process.env.PR_BASE_SHA ?? ''
		const headSha = process.env.PR_HEAD_SHA ?? ''
		if (!baseSha || !headSha) return null
		return { baseSha, headSha }
	}

	const baseSha = process.env.PUSH_BASE_SHA ?? ''
	const headSha = process.env.PUSH_HEAD_SHA ?? ''
	if (!baseSha || !headSha) return null
	return { baseSha, headSha }
}

function commitExists(sha: string): boolean {
	return runGit(['cat-file', '-e', `${sha}^{commit}`], true).success
}

function fetchCommit(sha: string) {
	runGit(['fetch', '--no-tags', '--depth=1', 'origin', sha], true)
}

async function main() {
	const shas = resolveShas()
	if (!shas) {
		console.log('No comparable SHAs found; skipping infra diff check.')
		process.exit(0)
	}

	const { baseSha, headSha } = shas

	if (baseSha === '0000000000000000000000000000000000000000') {
		console.log('Base SHA is empty/zero commit; skipping infra diff check.')
		process.exit(0)
	}

	if (!commitExists(baseSha)) fetchCommit(baseSha)
	if (!commitExists(headSha)) fetchCommit(headSha)

	if (!commitExists(baseSha) || !commitExists(headSha)) {
		console.log('Could not resolve SHAs for infra diff check; skipping.')
		process.exit(0)
	}

	const diff = runGit(['diff', '--name-only', baseSha, headSha], true)
	if (!diff.success) {
		console.log('Failed to diff SHAs for infra check; skipping.')
		process.exit(0)
	}

	const changedFiles = diff.stdout
		.split('\n')
		.map((file) => file.trim())
		.filter(Boolean)

	const infraFiles = changedFiles.filter(
		(file) => file === '.env.example' || file.startsWith('infra/')
	)

	if (infraFiles.length === 0) {
		console.log('No infra-related file changes detected.')
		process.exit(0)
	}

	console.log('Infra-related file changes detected:')
	for (const file of infraFiles) {
		console.log(file)
	}

	const message = [
		'Changes in infra/ or .env.example were found:',
		...infraFiles,
		'Review Railway/service infrastructure settings before or after deploy.'
	].join('\n')

	console.log(`::warning title=Infrastructure changes detected::${escapeAnnotation(message)}`)
}

main().catch((err) => {
	console.error('Unexpected error during infra diff check:', err)
	process.exit(0)
})
