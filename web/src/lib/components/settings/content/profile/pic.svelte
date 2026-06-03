<script lang="ts">
	import {
		IconPencil,
		IconX,
		IconArrowLeft,
		IconCheck,
		IconFileUploadFilled,
		IconZoomIn,
		IconZoomOut
	} from '@tabler/icons-svelte'
	import { createClass } from '@opensky/style'
	import { scale } from 'svelte/transition'
	import { wipeVertical } from '$ui/transition'
	import { type OnCropCompleteEvent } from 'svelte-easy-crop'
	import Cropper from 'svelte-easy-crop'
	import ZoomSlider from './zoom-slider.svelte'
	import {
		startProfilePicUpload,
		completeProfilePicUpload
	} from '$lib/remotes/storage/profile-pic.remote'
	import { createUpload } from '$utils/storage-upload.svelte'
	import { getUser } from '$remotes/auth/user.remote'

	interface Props {
		profilePic: string | null
	}

	let { profilePic }: Props = $props()

	// Build the content URL from the S3 key
	let profilePicUrl = $derived(profilePic ? `/content/${profilePic}` : null)

	const upload = createUpload({
		start: () => startProfilePicUpload().run(),
		complete: (token) => completeProfilePicUpload({ uploadToken: token })
	})

	let uploadedImageUrl = $state<string>()

	let isEditingPic = $state(false)
	let image = $derived(uploadedImageUrl ?? null)

	let crop = $state({ x: 0, y: 0 })
	let zoom = $state(1.0)
	let finalCrop = $state<null | OnCropCompleteEvent>(null)

	function reset() {
		uploadedImageUrl = undefined
		crop = { x: 0, y: 0 }
		zoom = 1.0
		finalCrop = null
	}

	// File Select Behaviors
	let fileInputEl = $state<HTMLInputElement>()

	function openFilePicker() {
		fileInputEl?.click()
	}
	function handleFileSelect(event: Event) {
		const target = event.target as HTMLInputElement
		const file = target.files?.[0]
		if (file) {
			processFile(file)
		}
	}

	// Dragging Behaviors
	let isDragging = $state(false)

	function handleDragOver(event: DragEvent) {
		event.preventDefault()
		isDragging = true
	}
	function handleDragLeave(event: DragEvent) {
		event.preventDefault()
		isDragging = false
	}
	function handleDragDrop(event: DragEvent) {
		event.preventDefault()
		isDragging = false

		const file = event.dataTransfer?.files?.[0]
		if (file) {
			processFile(file)
		}
	}

	// Validates and processes an uploaded image file, creating a blob URL for preview
	function processFile(file: File) {
		if (file && file.type.startsWith('image/')) {
			uploadedImageUrl = URL.createObjectURL(file)
		}
	}

	// Returns an image from a given blob url
	async function getImage(url: string): Promise<HTMLImageElement> {
		return new Promise((resolve, reject) => {
			const image = new Image()
			image.addEventListener('load', () => resolve(image))
			image.addEventListener('error', (error) => reject(error))
			image.src = url
		})
	}

	// Main function to resize image - returns a Blob for upload
	async function getCroppedImg(
		imageUrl: string,
		pixelCrop: { x: number; y: number; width: number; height: number }
	): Promise<Blob> {
		const image = await getImage(imageUrl)
		const canvas = document.createElement('canvas')
		const ctx = canvas.getContext('2d')

		if (!ctx) {
			throw new Error('No 2d context')
		}

		// Calculate the resize dimensions
		const maxSize = 300 // 300x300px
		let outputWidth = pixelCrop.width
		let outputHeight = pixelCrop.height

		if (outputWidth > maxSize || outputHeight > maxSize) {
			const scaleFactor = Math.min(maxSize / outputWidth, maxSize / outputHeight)
			outputWidth = Math.round(outputWidth * scaleFactor)
			outputHeight = Math.round(outputHeight * scaleFactor)
		}

		// Set canvas size to the resized dimensions
		canvas.width = outputWidth
		canvas.height = outputHeight

		// Draw the cropped and resized image
		ctx.drawImage(
			image,
			pixelCrop.x,
			pixelCrop.y,
			pixelCrop.width,
			pixelCrop.height,
			0,
			0,
			outputWidth,
			outputHeight
		)

		// Convert to JPEG with 85% quality
		return new Promise((resolve, reject) => {
			canvas.toBlob(
				(blob) => {
					if (!blob) {
						reject(new Error('Canvas is empty'))
						return
					}
					resolve(blob)
				},
				'image/jpeg',
				0.85
			)
		})
	}

	// Button Actions
	const handleSave = async () => {
		if (!finalCrop?.pixels) {
			console.error('Missing crop dimensions')
			return
		}

		if (!uploadedImageUrl) {
			console.error('No uploaded image')
			return
		}

		try {
			// Get the cropped image as a Blob
			const imageBlob = await getCroppedImg(uploadedImageUrl, finalCrop.pixels)

			await upload.send(imageBlob)

			// Refresh user data to get new profile pic
			await getUser().refresh()

			isEditingPic = false
			reset()
		} catch (error) {
			console.error('Error uploading image:', error)
		}
	}

	const handleCancel = () => {
		const hasImage = !!image

		// Reset all image-related state
		reset()

		// Close the editing UI if we were on the upload screen (no image loaded)
		if (!hasImage) {
			isEditingPic = false
		}
	}

	const zoomIn = () => {
		zoom += 0.25
	}
	const zoomOut = () => {
		zoom -= 0.25
	}
</script>

<div class="flex min-h-20 flex-col">
	{#if !isEditingPic}
		<div
			in:scale={{ start: 0.5, duration: 200, delay: 150 }}
			out:scale={{ start: 0.5, duration: 175 }}
			class="z-10 flex w-full items-center justify-center gap-5"
		>
			<button
				onclick={() => (isEditingPic = true)}
				class="group relative aspect-square h-20 w-20 cursor-pointer overflow-hidden rounded-full"
			>
				<div
					class="absolute inset-0 z-40 flex h-full w-full items-center justify-center opacity-0 transition-opacity delay-75 group-hover:opacity-100"
				>
					<IconPencil size={34} />
				</div>
				<!-- Darkening overlay on hover -->
				<div
					class="absolute inset-0 z-30 h-full w-full bg-black/0 transition-colors delay-75 group-hover:bg-black/50"
				></div>
				<!-- Profile image -->
				{#if profilePicUrl}
					<div class="absolute inset-0 z-20">
						<img src={profilePicUrl} alt="" />
					</div>
				{/if}
				<!-- Placeholder/background -->
				<div
					class="absolute inset-0 z-10 h-full w-full bg-linear-to-b from-neutral-300 to-sky-200"
				></div>
			</button>
		</div>
	{:else}
		<div
			in:wipeVertical={{ duration: 200, delay: 175 }}
			out:wipeVertical={{ duration: 150 }}
			class={createClass('relative z-20 mb-5 flex flex-col gap-4')}
		>
			<input
				bind:this={fileInputEl}
				type="file"
				accept="image/*"
				onchange={handleFileSelect}
				class="hidden"
			/>

			<div class="absolute inset-0 z-100 flex h-fit w-full items-center justify-between p-2">
				<button
					onclick={handleCancel}
					class="flex h-9 w-9 items-center justify-center rounded-full bg-neutral-700/80 text-neutral-300 shadow active:scale-95"
				>
					{#if !image}
						<IconX />
					{:else}
						<IconArrowLeft />
					{/if}
				</button>

				<div class="grow"></div>

				{#if !!image}
					<button
						onclick={handleSave}
						class="flex h-9 w-9 cursor-pointer items-center justify-center rounded-full bg-linear-to-b from-blue-vibrant to-sky-500 shadow-[inset_0.5px_0.5px_0_rgba(255,255,255,0.2)] transition-transform active:scale-95"
					>
						<IconCheck />
					</button>
				{/if}
			</div>

			{#if !image}
				<div
					class={createClass(
						'flex h-64 w-64 cursor-pointer flex-col items-center justify-center gap-4 rounded-3xl outline-2 transition-colors focus:outline-blue-500',
						isDragging
							? 'bg-blue-900/40 outline-blue-500'
							: 'bg-[#212121] shadow-[inset_0_1px_1.5px_rgba(255,255,255,0.11),inset_0_-1px_4px_rgba(255,255,255,0.05)] outline-neutral-700/0'
					)}
					role="button"
					tabindex="0"
					ondrop={handleDragDrop}
					onclick={openFilePicker}
					ondragover={handleDragOver}
					ondragleave={handleDragLeave}
					onkeydown={(e) => e.key === 'Enter' && openFilePicker()}
				>
					<IconFileUploadFilled size={50} class="text-neutral-300" />
					<div class="text-center">
						<p class="font-semibold text-neutral-300">Drop an image</p>
						<p class="font-medium text-neutral-400">or click to browse</p>
					</div>
				</div>
			{:else if image}
				<div class="flex flex-col gap-3">
					<div class="relative h-64 w-64 overflow-hidden rounded-3xl bg-neutral-700">
						<Cropper
							{image}
							cropShape="round"
							aspect={1.0}
							showGrid={false}
							bind:crop
							bind:zoom
							oncropcomplete={(e: OnCropCompleteEvent) => {
								finalCrop = e
							}}
						/>
					</div>

					<div class="flex h-fit w-full items-center justify-center gap-2 text-neutral-300">
						<button onclick={zoomOut}>
							<IconZoomOut />
						</button>

						<ZoomSlider bind:value={zoom} />

						<button onclick={zoomIn}>
							<IconZoomIn />
						</button>
					</div>

					{#if upload.isUploading}
						<p>Uploading...</p>
					{/if}

					{#if upload.error}
						<p>Upload Error</p>
					{/if}
				</div>
			{/if}
		</div>
	{/if}
</div>
