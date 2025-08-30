#!/usr/bin/env bash
set -euo pipefail

APP="${1:-api-client}"   # package folder / name
PM="${2:-npm}"           # npm | pnpm
OPENAPI_ARG="${3:-}"     # optional: URL or path to spec

# Package-manager shims
case "$PM" in
  npm)
    INIT=(npm init -y)
    ADD=(npm install)
    ADD_DEV=(npm install -D)
    RUN="npm run"
    ;;
  pnpm)
    INIT=(pnpm init)
    ADD=(pnpm add)
    ADD_DEV=(pnpm add -D)
    RUN="pnpm run"
    ;;
  *)
    echo "Unsupported package manager: $PM (use npm or pnpm)"; exit 1;;
esac

echo "Scaffolding TypeScript OpenAPI client in '$APP'…"
mkdir -p "$APP"
pushd "$APP" >/dev/null

# 1) Basic package
"${INIT[@]}"

# 2) Deps
# - Runtime: openapi-fetch, zod
# - Dev: typescript, tsup, @types/node, openapi-typescript
"${ADD[@]}" openapi-fetch zod
"${ADD_DEV[@]}" typescript tsup @types/node openapi-typescript

# 3) tsconfig
cat > tsconfig.json <<'JSON'
{
  "compilerOptions": {
    "target": "ES2021",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "strict": true,
    "skipLibCheck": true,
    "declaration": true,
    "outDir": "dist",
    "baseUrl": ".",
    "paths": { "@/*": ["src/*"] }
  },
  "include": ["src", "scripts"]
}
JSON

# 4) Project layout
mkdir -p src/lib/api scripts

# 5) Generator script (plain Node ESM: no ts-node required)
cat > scripts/generate_api.mjs <<'JS'
import { execSync } from "node:child_process";
import { mkdirSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";
import process from "node:process";

const OPENAPI = process.env.OPENAPI || process.argv[2];
if (!OPENAPI) {
  console.error("Usage: OPENAPI=<url|path> node scripts/generate_api.mjs");
  console.error("   or: node scripts/generate_api.mjs <url|path>");
  process.exit(1);
}

const outDir = resolve("src/lib/api");
const typesFile = resolve(outDir, "types.ts");
mkdirSync(outDir, { recursive: true });

// Generate TypeScript types from OpenAPI
execSync(`openapi-typescript "${OPENAPI}" --output "${typesFile}"`, { stdio: "inherit" });

// Minimal typed client using openapi-fetch
const clientSource = `
// Auto-generated scaffold. Edit as you see fit.
import createClient from "openapi-fetch";
import type { paths } from "./types";

export const api = createClient<paths>({
  baseUrl: process.env.API_BASE_URL || process.env.NEXT_PUBLIC_API_BASE_URL || "",
  // customize: headers, auth, fetch, etc.
});

// Example helper (remove if not needed):
export async function health() {
  return api.GET("/health");
}
`;
writeFileSync(resolve(outDir, "client.ts"), clientSource);

console.log("✔ Generated src/lib/api/types.ts and src/lib/api/client.ts");
JS

# 6) Library entry
cat > src/index.ts <<'TS'
export * from "./lib/api/client";
export * as ApiTypes from "./lib/api/types";
TS

# 7) tsup config
cat > tsup.config.ts <<'TS'
import { defineConfig } from "tsup";
export default defineConfig({
  entry: ["src/index.ts"],
  format: ["esm", "cjs"],
  dts: true,
  sourcemap: true,
  clean: true,
  outDir: "dist",
  target: "es2021"
});
TS

# 8) Patch package.json
node <<'NODE'
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json','utf8'));

pkg.name ||= "api-client";
pkg.type = "module";
pkg.main = "./dist/index.cjs";
pkg.module = "./dist/index.js";
pkg.types = "./dist/index.d.ts";
pkg.files = ["dist"];

pkg.scripts = Object.assign({}, pkg.scripts, {
  "build": "tsup",
  "clean": "rm -rf dist",
  "generate:api": "node scripts/generate_api.mjs"
});

fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
NODE

# 9) README
cat > README.md <<'MD'