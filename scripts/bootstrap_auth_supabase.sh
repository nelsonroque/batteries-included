#!/usr/bin/env bash
set -euo pipefail

APP="${1:-supabase-app}"
PM="${2:-npm}"   # npm | pnpm

case "$PM" in
  npm)  CREATE=(npx create-next-app@latest "$APP" --ts --app --src-dir --no-tailwind --eslint --yes)
        ADD_DEV=(npm i -D); ADD=(npm i); EXEC=(npx); RUN_DEV="npm run dev" ;;
  pnpm) CREATE=(pnpm create next-app "$APP" --ts --app --src-dir --no-tailwind --eslint --yes)
        ADD_DEV=(pnpm add -D); ADD=(pnpm add); EXEC=(pnpm dlx); RUN_DEV="pnpm dev" ;;
  *) echo "Unsupported package manager: $PM (use npm or pnpm)"; exit 1;;
esac

echo "Scaffolding Next.js + Tailwind v4 + shadcn/ui + Supabase Auth in '$APP'…"
"${CREATE[@]}"
pushd "$APP" >/dev/null

# Tailwind v4
"${ADD_DEV[@]}" tailwindcss @tailwindcss/postcss postcss autoprefixer
cat > postcss.config.mjs <<'POSTCSS'
export default { plugins: { "@tailwindcss/postcss": {} } }
POSTCSS
mkdir -p src/app
printf '@import "tailwindcss";\n' > src/app/globals.css

# shadcn/ui + base components
"${ADD[@]}" lucide-react class-variance-authority clsx tailwind-merge tailwind-animate
"${EXEC[@]}" shadcn@latest init -y
"${EXEC[@]}" shadcn@latest add button card input label

# Supabase deps
"${ADD[@]}" @supabase/supabase-js @supabase/ssr

# env
cat > .env.local <<'ENV'
NEXT_PUBLIC_SUPABASE_URL=YOUR_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
# Optional API base for your own backend:
# NEXT_PUBLIC_API_BASE_URL=http://localhost:3000/api
ENV

# Supabase clients (server/browser)
mkdir -p src/lib/supabase
cat > src/lib/supabase/client.ts <<'TS'
"use client";
import { createBrowserClient } from "@supabase/ssr";
export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}
TS
cat > src/lib/supabase/server.ts <<'TS'
import { cookies } from "next/headers";
import { createServerClient, type CookieOptions } from "@supabase/ssr";

export function createClient() {
  const cookieStore = cookies();
  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) { return cookieStore.get(name)?.value; },
        set(name: string, value: string, options: CookieOptions) {
          cookieStore.set({ name, value, ...options });
        },
        remove(name: string, options: CookieOptions) {
          cookieStore.set({ name, value: "", ...options });
        },
      },
    }
  );
}
TS

# Auth UI & routes
mkdir -p src/app/(auth)/login src/app/(app)/protected
cat > src/app/page.tsx <<'TSX'
import Link from "next/link";
import { Button } from "@/components/ui/button";

export default function Home() {
  return (
    <main className="min-h-dvh grid place-items-center p-8">
      <div className="space-y-4 text-center">
        <h1 className="text-3xl font-bold">Supabase Auth Starter</h1>
        <p className="text-muted-foreground">Next.js + Tailwind v4 + shadcn/ui</p>
        <div className="flex items-center justify-center gap-2">
          <Button asChild><Link href="/(auth)/login">Login</Link></Button>
          <Button asChild variant="secondary"><Link href="/(app)/protected">Protected Page</Link></Button>
        </div>
      </div>
    </main>
  );
}
TSX

cat > src/app/(auth)/login/page.tsx <<'TSX'
"use client";
import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    const supabase = createClient();
    const { error } = await supabase.auth.signInWithOtp({ email });
    if (error) alert(error.message);
    else alert("Check your email for the magic link.");
  }
  return (
    <main className="min-h-dvh grid place-items-center p-6">
      <Card className="w-full max-w-sm">
        <CardHeader><CardTitle>Sign in</CardTitle></CardHeader>
        <CardContent>
          <form onSubmit={onSubmit} className="space-y-3">
            <Input type="email" placeholder="you@example.com" value={email} onChange={e=>setEmail(e.target.value)} required />
            <Button type="submit" className="w-full">Send magic link</Button>
          </form>
        </CardContent>
      </Card>
    </main>
  );
}
TSX

cat > src/app/(app)/protected/page.tsx <<'TSX'
import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import { Button } from "@/components/ui/button";
import Link from "next/link";

export default async function ProtectedPage() {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/(auth)/login");
  return (
    <main className="min-h-dvh grid place-items-center p-8">
      <div className="space-y-4 text-center">
        <h1 className="text-2xl font-semibold">Hello, {user.email}</h1>
        <form action="/auth/signout" method="post">
          <Button type="submit">Sign out</Button>
        </form>
        <Button asChild variant="secondary"><Link href="/">Home</Link></Button>
      </div>
    </main>
  );
}
TSX

# Sign-out route (Edge-friendly)
mkdir -p src/app/auth
cat > src/app/auth/signout/route.ts <<'TS'
import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function POST() {
  const supabase = createClient();
  await supabase.auth.signOut();
  return NextResponse.redirect(new URL("/", process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3000"));
}
TS

echo "🎉 Setup complete for '$APP'."
echo "Next steps:"
echo "  1) Put your Supabase project values in .env.local"
echo "  2) cd $APP && $RUN_DEV"
popd >/dev/null
