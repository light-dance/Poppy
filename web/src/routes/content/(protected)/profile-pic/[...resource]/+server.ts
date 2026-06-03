import { error } from '@sveltejs/kit'
import { serveProtected } from '$lib/server/storage'

export const GET = serveProtected({
	authorize: ({ locals, fileKey }) => {
		// Require authentication
		if (!locals.user) {
			throw error(401, 'Unauthorized')
		}

		// fileKey format: "profile-pic/{userId}/{timestamp}-{shortId}.jpg"
		// Extract userId from the path
		const parts = fileKey.split('/')
		const fileUserId = parts[1]

		// Verify the file belongs to the logged-in user
		if (fileUserId !== locals.user.id) {
			throw error(403, 'Forbidden')
		}
	}
})
