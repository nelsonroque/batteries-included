#!/usr/bin/env python3
import os
from pathlib import Path
from textwrap import dedent

APP_DIR = Path("app")  # App Router
COMP_DIR = APP_DIR / "components"

FILES = {
    # ---------- layout ----------
    APP_DIR / "layout.tsx": dedent("""\
        export const metadata = { title: "My App", description: "Generated boilerplate" };

        export default function RootLayout({ children }: { children: React.ReactNode }) {
          return (
            <html lang="en">
              <body className="min-h-screen bg-white text-gray-900 antialiased">{children}</body>
            </html>
          );
        }
    """),

    # ---------- components ----------
    COMP_DIR / "Hero.tsx": dedent("""\
        export default function Hero() {
          return (
            <section className="py-16 text-center">
              <h1 className="text-4xl font-bold tracking-tight">Welcome to My App</h1>
              <p className="mt-4 text-gray-600">Fast, modern, and generated in seconds.</p>
              <div className="mt-6 inline-flex gap-3">
                <a href="/about" className="px-4 py-2 rounded-lg border">Learn more</a>
                <a href="/contact" className="px-4 py-2 rounded-lg bg-black text-white">Contact</a>
              </div>
            </section>
          );
        }
    """),
    COMP_DIR / "Features.tsx": dedent("""\
        const features = [
          { title: "Speed", desc: "Next.js + App Router." },
          { title: "Typed", desc: "TypeScript-ready pages." },
          { title: "Style", desc: "Tailwind-friendly markup." },
        ];
        export default function Features() {
          return (
            <section className="py-12">
              <h2 className="text-2xl font-semibold text-center">Features</h2>
              <div className="mt-6 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
                {features.map(f => (
                  <div key={f.title} className="rounded-xl border p-5">
                    <div className="text-lg font-medium">{f.title}</div>
                    <p className="mt-2 text-gray-600">{f.desc}</p>
                  </div>
                ))}
              </div>
            </section>
          );
        }
    """),

    # ---------- pages ----------
    APP_DIR / "page.tsx": dedent("""\
        import Hero from "./components/Hero";
        import Features from "./components/Features";

        export default function HomePage() {
          return (
            <main className="container mx-auto max-w-5xl px-4">
              <Hero />
              <Features />
            </main>
          )
        }
    """),

    APP_DIR / "about/page.tsx": dedent("""\
        export default function AboutPage() {
          return (
            <main className="container mx-auto max-w-3xl px-4 py-12">
              <h1 className="text-3xl font-bold">About</h1>
              <p className="mt-4 text-gray-700">
                This is a prebuilt About page. Replace with your story, mission, and team.
              </p>
            </main>
          );
        }
    """),

    APP_DIR / "contact/page.tsx": dedent("""\
        export default function ContactPage() {
          return (
            <main className="container mx-auto max-w-3xl px-4 py-12">
              <h1 className="text-3xl font-bold">Contact</h1>
              <form className="mt-6 space-y-4 max-w-lg">
                <input className="w-full rounded border p-2" placeholder="Your email" type="email" />
                <textarea className="w-full rounded border p-2" placeholder="Message" rows={5} />
                <button className="rounded bg-black px-4 py-2 text-white" type="submit">Send</button>
              </form>
            </main>
          );
        }
    """),

    APP_DIR / "blog/page.tsx": dedent("""\
        import Link from "next/link";

        const posts = [
          { id: "hello-world", title: "Hello World" },
          { id: "second-post", title: "Second Post" },
        ];

        export default function BlogIndex() {
          return (
            <main className="container mx-auto max-w-3xl px-4 py-12">
              <h1 className="text-3xl font-bold">Blog</h1>
              <ul className="mt-6 space-y-3">
                {posts.map(p => (
                  <li key={p.id}>
                    <Link className="text-blue-600 underline" href={`/blog/${p.id}`}>{p.title}</Link>
                  </li>
                ))}
              </ul>
            </main>
          );
        }
    """),

    APP_DIR / "blog/[id]/page.tsx": dedent("""\
        interface Params { id: string }
        export default function BlogPost({ params }: { params: Params }) {
          return (
            <main className="container mx-auto max-w-3xl px-4 py-12">
              <h1 className="text-3xl font-bold">Post: {params.id}</h1>
              <p className="mt-4 text-gray-700">
                Replace with real content loaded from your CMS or filesystem.
              </p>
            </main>
          );
        }
    """),

    APP_DIR / "login/page.tsx": dedent("""\
        export default function LoginPage() {
          return (
            <main className="container mx-auto max-w-sm px-4 py-12">
              <h1 className="text-3xl font-bold">Login</h1>
              <form className="mt-6 space-y-4">
                <input className="w-full rounded border p-2" placeholder="Email" type="email" />
                <input className="w-full rounded border p-2" placeholder="Password" type="password" />
                <button className="w-full rounded bg-black px-4 py-2 text-white" type="submit">Sign in</button>
              </form>
            </main>
          );
        }
    """),

    APP_DIR / "logout/page.tsx": dedent("""\
        export default function LogoutPage() {
          return (
            <main className="container mx-auto max-w-3xl px-4 py-12">
              <h1 className="text-3xl font-bold">You’ve been logged out</h1>
              <p className="mt-4">This is a placeholder route. Wire it to your auth provider.</p>
            </main>
          );
        }
    """),
}

def write_file(path: Path, content: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        print(f"• Skipped (exists): {path}")
        return
    path.write_text(content)
    print(f"✓ Created: {path}")

def main():
    if not Path("package.json").exists():
        print("⚠️  Run this from the root of a Next.js project (package.json not found).")
        return

    for p, c in FILES.items():
        write_file(p, c)

    print("\nAll set! Start dev server with:\n  npm run dev   # or pnpm/yarn\n")

if __name__ == "__main__":
    main()
