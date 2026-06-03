<script lang="ts">
	import { setContext, type Snippet } from 'svelte'
	import { createClass } from '@opensky/style'
	import { Tween } from 'svelte/motion'
	import { cubicOut } from 'svelte/easing'

	type Props = {
		isShown?: boolean
		children: Snippet
		sidebarContent: Snippet
		class?: string
		minWidth?: number
		maxWidth?: number
		defaultWidth?: number
		resizable?: boolean
		side?: 'left' | 'right'
	}
	let {
		isShown: isShownProp = $bindable(true),
		children,
		sidebarContent,
		class: classProp,
		minWidth = 150,
		maxWidth = 500,
		defaultWidth = 300,
		resizable = true,
		side = 'left'
	}: Props = $props()

	let sidebar = $state({
		isShown: isShownProp
	})
	setContext('sidebar', sidebar)

	function getInitialContentWidth() {
		return defaultWidth
	}

	function getInitialSidebarWidth() {
		return sidebar.isShown ? contentWidth : 0
	}

	// Sizing
	let contentWidth = $state(getInitialContentWidth())
	let sidebarWidthTweened = new Tween(getInitialSidebarWidth(), {
		duration: 350,
		easing: cubicOut
	})
	let beforeResizingWidth = $state<number | null>(null)

	// Resizing
	let isResizing = $state(false)
	function startResize(event: MouseEvent) {
		isResizing = true
		event.preventDefault()
		beforeResizingWidth = contentWidth
	}
	function stopResize() {
		isResizing = false
		beforeResizingWidth = null
	}
	let containerWidth = $state(0)
	function resize(event: MouseEvent) {
		if (!isResizing) return

		let x
		if (side == 'left') {
			x = event.pageX
		} else {
			x = containerWidth - event.pageX
		}
		if (x < 25) {
			sidebar.isShown = !sidebar.isShown
			if (beforeResizingWidth !== null) {
				contentWidth = beforeResizingWidth
			}
			stopResize()
			return
		}
		const newWidth = Math.max(minWidth, Math.min(maxWidth, x))
		contentWidth = newWidth
		sidebarWidthTweened.set(newWidth, { duration: 0 })
	}

	// Show/Hide
	$effect(() => {
		if (!isResizing && !sidebar.isShown) {
			sidebarWidthTweened.target = 0
		} else if (!isResizing && sidebar.isShown) {
			sidebarWidthTweened.target = contentWidth
		}
	})
	$effect(() => {
		if (isShownProp) {
			sidebar.isShown = true
		} else if (!isShownProp) {
			sidebar.isShown = false
		}
	})
</script>

<svelte:window on:mouseup={stopResize} />

<div
	role="navigation"
	class={createClass('flex h-full w-full', side == 'right' ? 'flex-row-reverse' : '', classProp)}
	onmousemove={resize}
	bind:offsetWidth={containerWidth}
>
	<!-- Sidebar container -->
	<div
		style:width={`${sidebarWidthTweened.current}px`}
		class="relative h-full shrink-0 overflow-hidden"
	>
		<!-- Sidebar content -->
		<div
			style:width={`${contentWidth}px`}
			class={createClass(
				'absolute top-0 h-full transition-opacity delay-[25ms] duration-250',
				side == 'left' ? 'left-0' : 'right-0',
				sidebar.isShown ? 'opacity-100' : 'opacity-20'
			)}
		>
			{@render sidebarContent()}
		</div>
		<!-- Drag handle -->
		<div
			aria-hidden="true"
			class={createClass(
				'absolute top-0 h-full w-0 bg-blue-500 transition-all duration-200 has-hover:w-[3px] has-hover:opacity-100',
				!resizable && 'hidden',
				side == 'left' ? 'right-0' : 'left-0',
				isResizing ? 'w-[3px] opacity-100' : 'opacity-0'
			)}
			onmousedown={startResize}
		>
			<div
				class={createClass(
					'absolute top-0 h-full w-2.5 cursor-ew-resize',
					side == 'left' ? 'right-0' : 'left-0'
				)}
			></div>
		</div>
	</div>
	<!-- Main content -->
	<div class="h-full w-full">
		{@render children()}
	</div>
</div>
