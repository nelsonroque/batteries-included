#!/usr/bin/env bash
set -euo pipefail

APP="${1:-next-api-app}"
PM="${2:-npm}"   # npm | pnpm
OPENAPI="${3:-}" # optional; if empty we'll leave a generate script for later

case "$PM" in
  npm)  CREATE=(npx create-next-app@latest "$APP" --ts --app --src-dir --no-tailwind --eslint --yes)
        ADD_DEV=(npm i -D); ADD=(npm i); EXEC=(npx); RUN_DEV="npm run dev" ;;
  pnpm) CREATE=(pnpm create next-app "$APP" --ts --app --src-dir --no-tailwind --eslint --yes)
        ADD_DEV=(pnpm add -D); ADD=(pnpm add); EXEC=(pnpm dlx); RUN_DEV="pnpm dev" ;;
  *) echo "Unsupported package manager: $PM (use npm or pnpm)"; exit 1;;
endcase
echo "Scaffolding Next.js + Tailwind v4 + shadcn/ui + OpenAPI client in '$APP'…"
"${CREATE[@]}"
pushd "$APP" >/dev/null

# Tailwind v4
"${ADD_DEV[@]}" tailwindcss @tailwindcss/postcss postcss autoprefixer
cat > postcss.config.mjs <<'POSTCSS'
export default { plugins: { "@tailwindcss/postcss": {} } }
POSTCSS
mkdir -p src/app
printf '@import "tailwindcss";\n' > src/app/globals.css

# shadcn/ui baseline
"${ADD[@]}" lucide-react class-variance-authority clsx tailwind-merge tailwind-animate
"${EXEC[@]}" shadcn@latest init -y
"${EXEC[@]}" shadcn@latest add button card input label

# OpenAPI client deps
"${ADD[@]}" openapi-fetch openapi-typescript zod

# Client structure & generator
mkdir -p src/lib/api scripts
cat > scripts/generate_api.ts <<'TS'
import { execSync } from "node:child_process";
import { resolve } from "node:path";
import { mkdirSync, writeFileSync } from "node:fs";

const OPENAPI = process.env.OPENAPI || process.argv[2];
if (!OPENAPI) {
  console.error("Usage: OPENAPI=<url|path> next - OpenAPI generator");
  process.exit(1);
}
mkdirSync(resolve("src/lib/api"), { recursive: true });
execSync(`openapi-typescript "${OPENAPI}" --output src/lib/api/types.ts`, { stdio: "inherit" });

const client = `
import createClient from "openapi-fetch";
import type { paths } from "./types";

export const api = createClient<paths>({
  baseUrl: process.env.NEXT_PUBLIC_API_BASE_URL || "",
});
`;
writeFileSync("src/lib/api/client.ts", client);
console.log("✔ Generated src/lib/api/{types.ts,client.ts}");
TS

# package.json scripts patch
node <<'NODE'
const fs = require('fs'); const pkg = JSON.parse(fs.readFileSync('package.json','utf8'));
pkg.scripts = Object.assign({}, pkg.scripts, {
  "generate:api": "node --loader ts-node/esm scripts/generate_api.ts"
});
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
NODE

# Home page demo
cat > src/app/page.tsx <<'TSX'
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export default function Page() {
  return (
    <main className="min-h-dvh grid place-items-center p-8">
      <Card className="w-full max-w-xl">
        <CardHeader><CardTitle>Next.js + OpenAPI Client</CardTitle></CardHeader>
        <CardContent className="space-y-2 text-sm text-muted-foreground">
          <p>Run <code>OPENAPI=&lt;url|path&gt; npm run generate:api</code> to generate typed endpoints.</p>
          <p>Set <code>NEXT_PUBLIC_API_BASE_URL</code> to your API origin.</p>
        </CardContent>
      </Card>
    </main>
  );
}
TSX

# Env example
cat > .env.local <<'ENV'
# Base URL for your API (used by openapi-fetch client)
NEXT_PUBLIC_API_BASE_URL=http://localhost:3000
ENV

# Try generation if an OPENAPI was provided
if [[ -n "${OPENAPI}" ]]; then
  OPENAPI="$OPENAPI" node --loader ts-node/esm scripts/generate_api.ts || true
fi

echo "🎉 Setup complete for '$APP'."
echo "Next steps:"
echo "  cd $APP"
echo "  # (optional) generate client: OPENAPI=https://your-spec.json $PM run generate:api"
echo "  $RUN_DEV"
popd >/dev/null
