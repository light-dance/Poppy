import { env } from '$env/dynamic/private'
import { Database } from 'bun:sqlite'
import { drizzle } from 'drizzle-orm/bun-sqlite'

import * as schema from './schema/index'
// import { relations } from './relations'

if (!env.DB_URL) throw new Error('DB_URL is not set')

const client = new Database(env.DB_URL)

client.run('PRAGMA foreign_keys = ON')
client.run('PRAGMA journal_mode = WAL')

export const db = drizzle({ client, schema })
// export const db = drizzle({ client, schema, relations })
