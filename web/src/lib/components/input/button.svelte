<script lang="ts">
	import type { Snippet } from 'svelte'
	import type { Icon as TablerIcon } from '@tabler/icons-svelte'
	import { createClass, createVariants } from '@opensky/style'
	import { Suspense } from '$ui/feedback'

	type Props = {
		children: Snippet
		icon?: TablerIcon
		onClick?: (e?: MouseEvent) => void
		href?: string
		as?: string
		type?: 'button' | 'submit'
		suspense?: boolean
		class?: string
		disabled?: boolean
		// Variant Props
		style?: 'primary' | 'secondary' | 'outline' | 'ghost' | 'link'
		rounded?: 'full' | 'lg' | 'md' | 'sm'
		size?: 'sm' | 'md' | 'lg' | 'xl'
		role?: 'destructive'
	}

	let {
		children,
		icon: Icon,
		onClick,
		href,
		as,
		type = 'button',
		suspense = false,
		class: classProp,
		disabled,
		// Style props
		...restProps
	}: Props = $props()

	const variantOptions = {
		base: 'font-medium text-[0.95rem] px-3.5 py-1.5 transition-all duration-100 flex items-center justify-center whitespace-nowrap relative active:scale-[0.97]',
		reset: '',
		style: {
			primary: 'bg-neutral-700 font-medium text-white hover:bg-neutral-800 hover:shadow-sm',
			secondary: 'bg-neutral-150 box-content font-medium text-neutral-800 hover:bg-neutral-200',
			outline:
				'shadow-card border-1 border-neutral-200 font-medium text-neutral-800 hover:border-neutral-300 hover:bg-neutral-100',
			ghost: 'text-vibrant-blue rounded-full bg-transparent font-medium hover:bg-blue-50',
			link: 'underline text-neutral-700 hover:text-neutral-900',
			_default: 'secondary'
		},
		rounded: {
			full: 'rounded-full',
			lg: 'rounded-[0.9rem]',
			md: 'rounded-[0.75rem]',
			sm: 'rounded-[0.6rem]',
			_default: 'full'
		},
		size: {
			sm: 'text-[0.87rem] px-3.5 py-1.5',
			md: 'text-[0.91rem] px-3.5 py-1.5',
			lg: 'text-[1.05rem] px-4 py-1.5',
			xl: 'text-[1.15rem] px-7 py-3',
			_default: 'md'
		},
		role: {
			destructive: 'text-rose-500 hover:text-rose-600'
		},
		compound: [
			{
				style: 'primary',
				role: 'destructive',
				classes: 'bg-red-500 text-rose-50 bg-red-500 hover:text-rose-50 hover:bg-red-600'
			},
			{
				style: 'secondary',
				role: 'destructive',
				classes: 'bg-red-100 text-rose-500 hover:bg-red-200 hover:text-rose-600'
			},
			{
				style: 'ghost',
				role: 'destructive',
				classes: 'bg-transparent text-rose-500 hover:bg-red-100'
			},
			{
				style: 'outline',
				role: 'destructive',
				classes:
					'hover:border-red-300 bg-transparent text-rose-500 hover:bg-red-100 hover:border-red-200'
			}
		]
	}

	let variants = $derived(createVariants(variantOptions, { ...restProps }))
</script>

{#if as}
	<svelte:element this={as} class={createClass(variants.classes, classProp)} role="button">
		{#if suspense}
			<div class="flex h-full items-center pr-1">
				<Suspense.Spinner size={16} />
			</div>
		{:else if Icon}
			<div class="flex h-full items-center pr-1">
				<Icon />
			</div>
		{/if}
		{@render children?.()}
	</svelte:element>
{:else if href}
	<!-- eslint-disable svelte/no-navigation-without-resolve -->
	<a
		{href}
		onclick={(e) => {
			if (onClick) {
				onClick(e)
			}
		}}
		class={createClass(variants.classes, classProp)}
	>
		<!-- eslint-enable svelte/no-navigation-without-resolve -->
		{#if Icon}
			<div class="flex h-full items-center pr-1">
				<Icon />
			</div>
		{/if}
		{@render children?.()}</a
	>
{:else}
	<button
		{type}
		{disabled}
		onclick={(e) => {
			if (onClick) {
				onClick(e)
			}
		}}
		class={createClass(variants.classes, classProp)}
	>
		{#if suspense}
			<div class="flex h-full items-center pr-1">
				<Suspense.Spinner size={16} />
			</div>
		{:else if Icon}
			<div class="flex h-full items-center pr-1">
				<Icon />
			</div>
		{/if}
		{@render children?.()}
	</button>
{/if}
