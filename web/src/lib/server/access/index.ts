import { createRule } from './build'
import isAdminCheck from './checks/is-admin'
import planCheck from './checks/plan'
import { createAccessHandle, createLocal } from './hook'

const Access = {
	isAdmin: createRule(isAdminCheck),
	plan: createRule(planCheck)
}

export const AccessHooks = {
	handleAccess: createAccessHandle({
		plan: createLocal(planCheck)
	})
}

export default Access

export { defineCheck } from './types'
export type { Access as AccessType } from './types'
