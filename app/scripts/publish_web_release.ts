function requiredEnv(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

type ReleaseMetadata = {
  version: string;
  build_number: string | number;
  title: string;
  changelog: string;
};

function releaseMetadataPath(version: string): string {
  return `app/releases/${version}.json`;
}

async function readReleaseMetadata(version: string): Promise<ReleaseMetadata> {
  const path = releaseMetadataPath(version);
  const file = Bun.file(path);

  if (!(await file.exists())) {
    throw new Error(
      `Missing release metadata file: ${path}. Tag releases must commit app/releases/<version>.json with version, build_number, title, and changelog.`,
    );
  }

  let metadata: unknown;
  try {
    metadata = JSON.parse(await file.text());
  } catch (error) {
    throw new Error(
      `Invalid release metadata JSON in ${path}: ${
        error instanceof Error ? error.message : String(error)
      }`,
    );
  }

  if (!metadata || typeof metadata !== "object") {
    throw new Error(`Invalid release metadata in ${path}: expected an object.`);
  }

  const release = metadata as Partial<ReleaseMetadata>;
  const metadataVersion = release.version?.trim();
  const title = release.title?.trim();
  const changelog = release.changelog?.trim();

  if (!metadataVersion) {
    throw new Error(`Missing release metadata field: version in ${path}.`);
  }
  if (metadataVersion !== version) {
    throw new Error(
      `Release metadata version (${metadataVersion}) does not match release version (${version}).`,
    );
  }
  if (
    release.build_number === undefined ||
    `${release.build_number}`.trim() === ""
  ) {
    throw new Error(`Missing release metadata field: build_number in ${path}.`);
  }
  if (!title) {
    throw new Error(`Missing release metadata field: title in ${path}.`);
  }
  if (!changelog) {
    throw new Error(`Missing release metadata field: changelog in ${path}.`);
  }

  return {
    version: metadataVersion,
    build_number: release.build_number,
    title,
    changelog,
  };
}

async function resolveVersion(): Promise<string> {
  const inputVersion = process.env.POPPY_INPUT_VERSION?.trim();
  if (inputVersion) {
    return inputVersion;
  }

  if (process.env.GITHUB_REF_TYPE === "tag" && process.env.GITHUB_REF_NAME) {
    return process.env.GITHUB_REF_NAME.replace(/^v/, "");
  }

  throw new Error(
    "Missing release version. Pass workflow input version or push a v* tag.",
  );
}

async function resolveMetadata() {
  const version = await resolveVersion();
  let title = process.env.POPPY_RELEASE_TITLE?.trim() || null;
  let changelog = process.env.POPPY_RELEASE_CHANGELOG?.trim() || "";

  if (
    (!title || !changelog) &&
    process.env.GITHUB_REF_TYPE === "tag" &&
    process.env.GITHUB_REF_NAME
  ) {
    const metadata = await readReleaseMetadata(version);
    title ||= metadata.title;
    changelog ||= metadata.changelog;
  }

  if (!changelog) {
    throw new Error(
      "Missing release changelog. Provide the workflow changelog input or commit app/releases/<version>.json for tag releases.",
    );
  }

  return { version, title, changelog };
}

async function main() {
  const endpoint = requiredEnv("POPPY_RELEASE_API_URL");
  const token = requiredEnv("POPPY_RELEASE_API_TOKEN");
  const release = await resolveMetadata();
  const body = release.title
    ? release
    : {
        version: release.version,
        changelog: release.changelog,
      };

  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      authorization: `Bearer ${token}`,
      "content-type": "application/json",
    },
    body: JSON.stringify(body),
  });

  const text = await response.text();
  let payload: unknown;

  try {
    payload = JSON.parse(text);
  } catch {
    payload = text;
  }

  if (!response.ok) {
    throw new Error(`Release API returned ${response.status}: ${text}`);
  }

  if (
    !payload ||
    typeof payload !== "object" ||
    !("success" in payload) ||
    payload.success !== true
  ) {
    throw new Error(`Release API did not return success: true: ${text}`);
  }

  console.log(`Published web release metadata for ${release.version}`);
}

main().catch((error) => {
  console.error("Failed to publish web release metadata:", error.message);
  process.exit(1);
});
