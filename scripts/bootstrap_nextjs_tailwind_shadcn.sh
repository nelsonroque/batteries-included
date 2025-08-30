#!/usr/bin/env bash
set -euo pipefail

APP="${1:-my-app}"
PM="${2:-npm}"   # npm | pnpm

# shadcn starter components (adjust as you like)
SHADCN_COMPONENTS=("button" "card" "input" "textarea")

# Package-manager shims
case "$PM" in
  npm)
    CREATE=(npx create-next-app@latest "$APP" --ts --eslint --app --src-dir --no-tailwind --yes)
    ADD_DEV=(npm install -D)
    ADD=(npm install)
    EXEC=(npx)
    RUN_DEV="npm run dev"
    ;;
  pnpm)
    CREATE=(pnpm create next-app "$APP" --ts --eslint --app --src-dir --no-tailwind --yes)
    ADD_DEV=(pnpm add -D)
    ADD=(pnpm add)
    EXEC=(pnpm dlx)
    RUN_DEV="pnpm dev"
    ;;
  *)
    echo "Unsupported package manager: $PM (use npm or pnpm)"; exit 1;;
esac

echo "Initializing Next.js + Tailwind v4 + shadcn/ui…"
"${CREATE[@]}"

pushd "$APP" >/dev/null

# Deps
# Tailwind v4 uses the PostCSS plugin package '@tailwindcss/postcss'
"${ADD_DEV[@]}" tailwindcss @tailwindcss/postcss postcss autoprefixer
"${ADD[@]}" tesseract.js chrono-node ics file-saver lucide-react \
  clsx class-variance-authority tailwind-merge tailwind-animate

# PostCSS config for Tailwind v4 (idempotent overwrite is fine; create-next-app doesn't add this when --no-tailwind)
cat > postcss.config.mjs <<'POSTCSS'
export default {
  plugins: {
    '@tailwindcss/postcss': {},
  },
}
POSTCSS

# Tailwind v4 entry (globals.css) – keep only the import
# create-next-app makes this file; we overwrite to ensure a clean v4 setup
mkdir -p src/app
printf '@import "tailwindcss";\n' > src/app/globals.css

# Ensure layout imports globals (create-next-app already does; keep idempotent)
# (No-op if already present)
node <<'NODE'
const fs = require('fs');
const p = 'src/app/layout.tsx';
if (fs.existsSync(p)) {
  let s = fs.readFileSync(p,'utf8');
  if (!/globals\.css/.test(s)) {
    s = `import './globals.css';\n` + s;
  }
  fs.writeFileSync(p, s);
}
NODE

# tsconfig.json patch (safe/idempotent) for '@' alias
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

# shadcn/ui
"${EXEC[@]}" shadcn@latest init -y
"${EXEC[@]}" shadcn@latest add "${SHADCN_COMPONENTS[@]}"

# Add a simple home page that uses shadcn/ui (idempotent: only create if missing)
if [[ ! -f src/app/page.tsx ]]; then
  mkdir -p src/app
  cat > src/app/page.tsx <<'PAGE'
export default function Page() {
  return (
    <main className="min-h-dvh flex items-center justify-center p-8">
      <div className="max-w-md text-center space-y-4">
        <h1 className="text-3xl font-bold tracking-tight">Next.js + Tailwind v4 + shadcn/ui</h1>
        <p className="text-muted-foreground">Happy building!</p>
      </div>
    </main>
  );
}
PAGE
fi

popd >/dev/null

cat <<MSG

🎉 Setup complete.

Next steps:
  cd $APP
  $RUN_DEV
MSG
