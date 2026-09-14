import { includeIgnoreFile } from '@eslint/compat'
import { defineConfig, globalIgnores } from 'eslint/config'
import { fileURLToPath } from 'node:url'

import js from '@eslint/js'
import ts from 'typescript-eslint'
import svelte from 'eslint-plugin-svelte'
import prettier from 'eslint-config-prettier'
import globals from 'globals'
import svelteConfig from './svelte.config.js'

const gitignorePath = fileURLToPath(new URL('./.gitignore', import.meta.url))

export default defineConfig(
	includeIgnoreFile(gitignorePath),
	globalIgnores(['.svelte-kit/**', 'build/**']),
	js.configs.recommended,
	...ts.configs.recommended,
	...svelte.configs.recommended,
	prettier,
	...svelte.configs.prettier,
	{
		files: ['src/lib/components/adapt/{reveal,swap,switch}.svelte'],
		rules: {
			// These callbacks are read by parents through $bindable props
			'no-useless-assignment': 'off'
		}
	},
	{
		languageOptions: {
			globals: { ...globals.browser, ...globals.node }
		},
		rules: {
			// typescript-eslint strongly recommend that you do not use the no-undef lint rule on TypeScript projects
			'no-undef': 'off',
			// Enable processing of eslint-disable comments in Svelte HTML
			'svelte/comment-directive': [
				'error',
				{
					reportUnusedDisableDirectives: true
				}
			]
		}
	},
	{
		files: ['**/*.svelte', '**/*.svelte.ts', '**/*.svelte.js'],
		languageOptions: {
			parserOptions: {
				projectService: true,
				extraFileExtensions: ['.svelte'],
				parser: ts.parser,
				svelteConfig
			}
		}
	}
)
