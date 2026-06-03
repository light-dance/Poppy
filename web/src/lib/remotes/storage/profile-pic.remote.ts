import { query, command, getRequestEvent } from '$app/server'
import { error } from '@sveltejs/kit'
import * as v from 'valibot'

import { db } from '$lib/server/db'
import { eq } from 'drizzle-orm'
import { user } from '$lib/server/db/schema'

import { defineUpload, s3 } from '$lib/server/storage'

// Defines the upload route for storage
const profilePicUpload = defineUpload({
	maxSize: '3MB',
	fileType: 'image/jpeg',
	expiresIn: 3 * 60, // 3 mins
	customKey: (input: { userId: string }) => {
		const timestamp = Date.now()
		const shortId = crypto.randomUUID().slice(0, 8)

		return `profile-pic/${input.userId}/${timestamp}-${shortId}.jpg`
	},
	metadata: v.object({
		userId: v.string(),
		message: v.optional(v.string())
	})
})

export const startProfilePicUpload = query(async () => {
	const { locals } = getRequestEvent()

	if (!locals.user) {
		throw error(401, 'Unauthorized')
	}

	const userId = locals.user.id

	// Get presigned URL for upload
	const result = await profilePicUpload.start({
		contentType: 'image/jpeg',
		key: { userId },
		metadata: { userId, message: 'Hello world, test!' }
	})

	return {
		uploadUrl: result.uploadUrl,
		uploadToken: result.uploadToken,
		uploadHeaders: result.uploadHeaders
	}
})

export const completeProfilePicUpload = command(
	v.object({
		uploadToken: v.string()
	}),
	async ({ uploadToken }) => {
		// Verify upload and get data
		const { fileKey, metadata } = await profilePicUpload.complete(uploadToken)

		// Cleanup old profile pics
		await cleanupOldProfilePics(metadata.userId)

		// Update user's profile picture in database
		await db.update(user).set({ profilePic: fileKey }).where(eq(user.id, metadata.userId))

		return { success: true, fileKey }
	}
)

async function cleanupOldProfilePics(userId: string): Promise<void> {
	/** Keep 6 files (show 5 most recent, delete oldest on new upload) */
	const HISTORY_LIMIT = 6

	const prefix = `profile-pic/${userId}/`

	try {
		// List all profile pics for this user
		const listResult = await s3.list({ prefix })

		if (!listResult.contents || listResult.contents.length <= HISTORY_LIMIT) {
			return // Nothing to clean up
		}

		// Sort by key (which includes timestamp) - oldest first
		const sortedFiles = listResult.contents.sort((a, b) => {
			const getTimestamp = (key: string) => {
				const filename = key.split('/').pop() || ''
				const timestamp = parseInt(filename.split('-')[0], 10)
				return isNaN(timestamp) ? 0 : timestamp
			}
			return getTimestamp(a.key) - getTimestamp(b.key)
		})

		// Delete oldest files, keeping HISTORY_LIMIT
		const filesToDelete = sortedFiles.slice(0, sortedFiles.length - HISTORY_LIMIT)

		for (const file of filesToDelete) {
			await s3.delete(file.key)
		}
	} catch (err) {
		// Log but don't fail the upload if cleanup fails
		console.error('Failed to cleanup old profile pics:', err)
	}
}
