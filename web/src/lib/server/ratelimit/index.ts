import { limits } from './limits'
import { handleGlobalRatelimit } from './global-hook'

export const ratelimit = {
	handleGlobalRatelimit,
	...limits
}

export default ratelimit
