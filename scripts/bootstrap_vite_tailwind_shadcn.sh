#!/usr/bin/env bash
set -euo pipefail

APP="${1:-my-app}"
PM="${2:-npm}"   # npm | pnpm

# shadcn starter components (adjust as you like)
SHADCN_COMPONENTS=("button" "card" "input" "textarea")

# Package-manager shims
case "$PM" in
  npm)
    CREATE=(npm create vite@latest "$APP" -- --template react-ts)
    ADD_DEV=(npm install -D)
    ADD=(npm install)
    EXEC=(npx)
    RUN_DEV="npm run dev"
    ;;
  pnpm)
    CREATE=(pnpm create vite "$APP" --template react-ts)
    ADD_DEV=(pnpm add -D)
    ADD=(pnpm add)
    EXEC=(pnpm dlx)
    RUN_DEV="pnpm run dev"
    ;;
  *)
    echo "Unsupported package manager: $PM (use npm or pnpm)"; exit 1;;
esac

echo "Initializing Vite + Tailwind v4 + shadcn/ui…"
"${CREATE[@]}"

pushd "$APP" >/dev/null

# Deps
"${ADD_DEV[@]}" tailwindcss @tailwindcss/vite postcss autoprefixer
"${ADD[@]}" tesseract.js chrono-node ics file-saver lucide-react \
  clsx class-variance-authority tailwind-merge tailwind-animate

# Tailwind v4 entry
mkdir -p src
printf '@import "tailwindcss";\n' > src/index.css

# tsconfig.json patch (safe/idempotent)
node <<'NODE'
const fs = require('fs');
const p = 'tsconfig.json';
const j = JSON.parse(fs.readFileSync(p,'utf8'));
j.compilerOptions = Object.assign({}, j.compilerOptions, {
  baseUrl: '.',
  paths: Object.assign({}, (j.compilerOptions||{}).paths, { '@/*': ['./src/*'] })
});
fs.writeFileSync(p, JSON.stringify(j,null,2));
NODE

# vite.config.ts patch: add imports, tailwindcss() plugin, and '@' alias (idempotent)
if [[ -f vite.config.ts ]]; then
node <<'NODE'
const fs = require('fs');
const path = require('path');
const p = 'vite.config.ts';
let s = fs.readFileSync(p,'utf8');

// ensure imports
if (!s.includes("import tailwindcss")) {
  s = "import tailwindcss from '@tailwindcss/vite';\n" + s;
}
if (!s.includes("import path from 'path'")) {
  s = "import path from 'path';\n" + s;
}

// add tailwindcss() to plugins if missing
s = s.replace(/plugins:\s*\[([\s\S]*?)\]/, (m, inner) => {
  if (/\btailwindcss\(\)/.test(inner)) return m;
  const t = inner.trim();
  return `plugins: [${t}${t ? ', ' : ''}tailwindcss()]`;
});

// add '@' alias if missing
if (!/resolve:\s*\{[^}]*alias:/.test(s)) {
  s = s.replace(/defineConfig\(\{/, "defineConfig({\n  resolve: { alias: { '@': path.resolve(__dirname, './src') } },");
} else {
  s = s.replace(/alias:\s*\{([\s\S]*?)\}/, (m, inner) => {
    if (inner.includes("'@':") || inner.includes('"@":')) return m;
    const t = inner.trim();
    const inj = t ? `${t}, '@': path.resolve(__dirname,'./src')` : "'@': path.resolve(__dirname,'./src')";
    return `alias: { ${inj} }`;
  });
}

fs.writeFileSync(p, s);
NODE
fi

# shadcn/ui
"${EXEC[@]}" shadcn@latest init -y
"${EXEC[@]}" shadcn@latest add "${SHADCN_COMPONENTS[@]}"

popd >/dev/null

cat <<MSG

🎉 Setup complete.

Next steps:
  cd $APP
  $RUN_DEV
MSG
