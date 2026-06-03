import adapter from 'svelte-adapter-bun'
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte'

/** @type {import('@sveltejs/kit').Config} */
const config = {
	preprocess: vitePreprocess(),
	compilerOptions: {
		experimental: {
			async: true
		}
	},
	kit: {
		adapter: adapter(),
		experimental: {
			remoteFunctions: true,
			tracing: { server: true },
			instrumentation: { server: true }
		},
		alias: {
			$remotes: 'src/lib/remotes',
			$ui: 'src/lib/components/',
			$utils: 'src/lib/utils/',
			$theme: 'src/lib/theme/'
		}
	}
}

export default config
