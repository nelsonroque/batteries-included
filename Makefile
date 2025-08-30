# Makefile for project bootstrapping with Tailwind v4 + shadcn/ui
#
# Variables:
#   APP – project name (default: my-app)
#   PM  – package manager: npm | pnpm (default: npm)
#
# Usage examples:
#   make bootstrap-vite-tailwind-shadcn APP=my-new-vite-app
#   make bootstrap-nextjs-tailwind-shadcn APP=my-next-app PM=pnpm

APP ?= my-app2
PM  ?= npm

.PHONY: bootstrap-vite-tailwind-shadcn bootstrap-nextjs-tailwind-shadcn

# Bootstrap a new Vite + React + TS project with Tailwind v4 + shadcn/ui
bootstrap-vite-tailwind-shadcn:
	./scripts/bootstrap_vite_tailwind_shadcn.sh $(APP) $(PM)

# Bootstrap a new Next.js (App Router) + TS project with Tailwind v4 + shadcn/ui
bootstrap-nextjs-tailwind-shadcn:
	./scripts/bootstrap_nextjs_tailwind_shadcn.sh $(APP) $(PM)
