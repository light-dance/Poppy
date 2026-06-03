import { basename } from "node:path";

const contentTypes: Record<string, string> = {
  ".dmg": "application/x-apple-diskimage",
  ".zip": "application/zip",
};

function requiredEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

function contentTypeFor(path: string): string {
  const extension = path.slice(path.lastIndexOf(".")).toLowerCase();
  return contentTypes[extension] ?? "application/octet-stream";
}

const args = Bun.argv.slice(2);
let prefix = "releases";
const files: string[] = [];

if (args.includes("-h") || args.includes("--help")) {
  console.log(`Usage:
  bun app/scripts/upload_railway_bucket.ts [--prefix PREFIX] FILE...

Environment:
  RAILWAY_BUCKET_ENDPOINT
  RAILWAY_BUCKET_NAME
  RAILWAY_BUCKET_ACCESS_KEY_ID
  RAILWAY_BUCKET_SECRET_ACCESS_KEY
  RAILWAY_BUCKET_REGION`);
  process.exit(0);
}

for (let index = 0; index < args.length; index += 1) {
  const arg = args[index];
  if (arg === "--prefix") {
    const value = args[index + 1];
    if (!value) {
      throw new Error("--prefix requires a value");
    }
    prefix = value;
    index += 1;
  } else {
    files.push(arg);
  }
}

if (files.length === 0) {
  throw new Error("No files provided for upload");
}

const client = new Bun.S3Client({
  endpoint: requiredEnv("RAILWAY_BUCKET_ENDPOINT"),
  bucket: requiredEnv("RAILWAY_BUCKET_NAME"),
  accessKeyId: requiredEnv("RAILWAY_BUCKET_ACCESS_KEY_ID"),
  secretAccessKey: requiredEnv("RAILWAY_BUCKET_SECRET_ACCESS_KEY"),
  region: process.env.RAILWAY_BUCKET_REGION || "auto",
});

const objectPrefix = prefix.replace(/^\/+|\/+$/g, "");

for (const path of files) {
  const file = Bun.file(path);
  if (!(await file.exists())) {
    throw new Error(`Missing file: ${path}`);
  }

  const key = objectPrefix ? `${objectPrefix}/${basename(path)}` : basename(path);
  await client.write(key, file, {
    type: contentTypeFor(path),
  });
  console.log(`Uploaded ${path} to s3://${requiredEnv("RAILWAY_BUCKET_NAME")}/${key}`);
}
