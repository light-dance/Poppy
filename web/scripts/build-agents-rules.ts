import { sections } from '../.agents/rules/config'

const rootDir = `${import.meta.dir}/..`
const sectionsDir = `${rootDir}/.agents/rules`
const outputPath = `${rootDir}/AGENTS.md`

function getLineCount(text: string) {
	const trimmed = text.endsWith('\n') ? text.slice(0, -1) : text
	return trimmed ? trimmed.split('\n').length : 0
}

function getCharCount(text: string) {
	return text.length
}

async function build() {
	const parts: string[] = []

	for (const section of sections) {
		const filePath = `${sectionsDir}/${section}.md`
		const file = Bun.file(filePath)

		if (!(await file.exists())) {
			console.error(`Section not found: ${section}.md`)
			process.exit(1)
		}

		const content = await file.text()
		parts.push(content.trim())
	}

	const output = parts.join('\n\n') + '\n'
	await Bun.write(outputPath, output)

	const lineCount = getLineCount(output)
	const charCount = getCharCount(output)
	console.log(
		`\x1b[32m✓ Built AGENTS.md\x1b[38;5;244m\x1b[1m (${sections.length} sections, ${lineCount} lines, ${charCount} chars)\x1b[0m`
	)
}

build()
