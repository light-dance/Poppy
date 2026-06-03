import { S3Client, RedisClient } from 'bun'
import { REDIS_URL } from '$env/static/private'

const s3 = new S3Client()
const redis = new RedisClient(REDIS_URL)

export { s3, redis }
