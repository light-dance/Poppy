function requiredEnv(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

async function gitTagContents(tag: string): Promise<string> {
  const proc = Bun.spawn(
    ["git", "for-each-ref", `refs/tags/${tag}`, "--format=%(contents)"],
    {
      stdout: "pipe",
      stderr: "pipe",
    },
  );

  const [stdout, stderr] = await Promise.all([
    new Response(proc.stdout).text(),
    new Response(proc.stderr).text(),
  ]);
  const exitCode = await proc.exited;

  if (exitCode !== 0) {
    throw new Error(`Failed to read tag contents: ${stderr.trim()}`);
  }

  return stdout.trim();
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
    !changelog &&
    process.env.GITHUB_REF_TYPE === "tag" &&
    process.env.GITHUB_REF_NAME
  ) {
    const tagContents = await gitTagContents(process.env.GITHUB_REF_NAME);
    const [tagTitle, ...tagBody] = tagContents.split(/\r?\n/);

    title ||= tagTitle?.trim() || null;
    changelog = tagBody.join("\n").trim() || tagContents;
  }

  if (!changelog) {
    throw new Error(
      "Missing release changelog. Provide the workflow changelog input or use an annotated tag message.",
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
