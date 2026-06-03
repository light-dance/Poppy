#!/usr/bin/env bun
/**
 * Checks that port 5173 (Vite dev server) is not already in use
 */

const PORT = 5173

async function getProcessOnPort(): Promise<{ pid: string; command: string } | null> {
	const proc = Bun.spawn(['lsof', `-iTCP:${PORT}`, '-sTCP:LISTEN', '-P', '-n', '-F', 'cp'])
	const text = await new Response(proc.stdout).text()
	await proc.exited

	if (!text.trim()) return null

	// -F cp output: one field per line, prefixed with field char (p=pid, c=command)
	let pid = ''
	let command = ''
	for (const line of text.trim().split('\n')) {
		if (line.startsWith('p')) pid = line.slice(1)
		else if (line.startsWith('c')) command = line.slice(1)
	}

	return pid ? { pid, command } : null
}

async function getProcessCwd(pid: string): Promise<string | null> {
	const proc = Bun.spawn(['lsof', '-p', pid])
	const text = await new Response(proc.stdout).text()
	await proc.exited

	for (const line of text.split('\n')) {
		const parts = line.trim().split(/\s+/)
		// Column 3 is the file descriptor type; "cwd" is the working directory entry
		if (parts[3] === 'cwd') return parts[parts.length - 1]
	}
	return null
}

async function main() {
	const found = await getProcessOnPort()

	if (!found) {
		console.log(`\x1b[32m✓ Port ${PORT} unused\x1b[0m`)
		return
	}

	const { pid, command } = found
	const cwd = await getProcessCwd(pid)
	const isSameProject = cwd === process.cwd()

	if (isSameProject) {
		console.error(`\x1b[31m✗ Dev server already running for this project\x1b[0m`)
	} else {
		console.error(`\x1b[31m✗ Port ${PORT} is in use by another process\x1b[0m`)
	}

	console.error(`\x1b[90m  ${command} (${pid}) ${cwd ?? 'unknown directory'}\x1b[0m`)
	console.error(`\x1b[90m  Stop process with \x1b[1mkill ${pid}\x1b[0m`)
	process.exit(1)
}

main().catch((err) => {
	console.error('\x1b[31m✗ Unexpected error:\x1b[0m', err.message)
	process.exit(1)
})
