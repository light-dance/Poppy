#!/usr/bin/env bun

type CommandResult = {
	success: boolean
	stdout: string
	stderr: string
}

function run(command: string[], quiet = false): CommandResult {
	const proc = Bun.spawnSync(command, {
		stdout: 'pipe',
		stderr: 'pipe'
	})

	const stdout = proc.stdout.toString().trim()
	const stderr = proc.stderr.toString().trim()
	const success = proc.exitCode === 0

	if (!success && !quiet) {
		const cmd = command.join(' ')
		console.error(`${cmd} failed:`)
		if (stderr) console.error(stderr)
	}

	return { success, stdout, stderr }
}

async function main() {
	const generate = run(['bun', 'drizzle-kit', 'generate'], true)
	if (!generate.success) {
		if (generate.stdout) console.log(generate.stdout)
		if (generate.stderr) console.error(generate.stderr)
		process.exit(1)
	}

	if (generate.stdout) console.log(generate.stdout)
	if (generate.stderr) console.error(generate.stderr)

	const status = run(['git', 'status', 'db/migrations', '--porcelain'], true)
	if (!status.success) {
		console.error('Failed to read git status for db/migrations.')
		process.exit(1)
	}

	if (!status.stdout) {
		console.log('Drizzle migrations are up to date.')
		process.exit(0)
	}

	console.log(
		"::error::Drizzle migrations are out of date. Run 'bun run db:gen' and commit the changes."
	)

	const humanStatus = run(['git', 'status', 'db/migrations'], true)
	if (humanStatus.stdout) console.log(humanStatus.stdout)
	if (humanStatus.stderr) console.error(humanStatus.stderr)

	const diff = run(['git', 'diff', 'db/migrations'], true)
	if (diff.stdout) console.log(diff.stdout)
	if (diff.stderr) console.error(diff.stderr)

	process.exit(1)
}

main().catch((err) => {
	console.error('Unexpected error while checking drizzle migrations:', err)
	process.exit(1)
})
