<script lang="ts">
	import { Button } from '$ui/input'
</script>

<div class="mx-auto flex min-h-full max-w-160 flex-col gap-2 bg-neutral-50 px-6 py-8">
	<div class="flex w-full justify-end">
		<Button href="/download" style="primary" rounded="full" class="w-fit bg-neutral-600">
			Download
		</Button>
	</div>

	<h1 class="text-lg font-medium">Poppy</h1>

	<div
		class="flex flex-col gap-2 py-3 text-[0.92rem]/5 font-medium tracking-[-0.01em] text-neutral-600"
	>
		<p>A small macOS utility for handling downloaded app installers.</p>
	</div>
</div>
