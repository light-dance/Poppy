import { env } from '$env/dynamic/private'
import { SQL } from 'bun'
import { drizzle } from 'drizzle-orm/bun-sql'

import * as schema from './schema/index'
import { relations } from './relations'

if (!env.DB_URL) throw new Error('DB_URL is not set')

const client = new SQL(env.DB_URL)

export const db = drizzle({ client, schema, relations })
