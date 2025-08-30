# Makefile for project bootstrapping with Tailwind v4 + shadcn/ui
#
# Variables (can be provided non-interactively, e.g., `make bootstrap STACK=nextjs PM=pnpm APP=my-app`):
#   APP   – project name (default: my-app)
#   STACK – vite | nextjs (default: ask interactively)
#   PM    – npm | pnpm (default: npm)
#
# Scripts expected:
#   ./scripts/bootstrap_vite_tailwind_shadcn.sh
#   ./scripts/bootstrap_nextjs_tailwind_shadcn.sh
#
# Examples:
#   make bootstrap                   # prompts for anything not provided
#   make bootstrap STACK=vite APP=demo
#   make bootstrap-nextjs-tailwind-shadcn APP=site PM=pnpm

SHELL := /usr/bin/env bash

APP ?= my-app
PM  ?= npm

.PHONY: bootstrap bootstrap-vite-tailwind-shadcn bootstrap-nextjs-tailwind-shadcn

# Interactive meta-target: prompts for STACK/APP/PM if not provided,
# then dispatches to the correct script.
bootstrap:
	@bash -eu -o pipefail -c '\
	  stack="$(STACK)"; \
	  app="$(APP)"; \
	  pm="$(PM)"; \
	  \
	  if [[ -z "$$stack" || "$$stack" = "ask" || "$$stack" = "-" ]]; then \
	    echo "Choose stack: [vite/nextjs]"; \
	    read -rp "Enter stack (vite/nextjs): " stack; \
	  fi; \
	  if [[ -z "$$app" || "$$app" = "my-app" ]]; then \
	    read -rp "Enter app name [my-app]: " in_app; \
	    app="$${in_app:-$$app}"; \
	  fi; \
	  if [[ -z "$$pm" || "$$pm" = "ask" || "$$pm" = "-" ]]; then \
	    read -rp "Enter package manager (npm/pnpm) [npm]: " in_pm; \
	    pm="$${in_pm:-npm}"; \
	  fi; \
	  case "$$pm" in npm|pnpm) ;; *) echo "Error: PM must be npm or pnpm (got '\''$$pm'\'')." >&2; exit 1;; esac; \
	  case "$$stack" in \
	    vite)   target="bootstrap-vite-tailwind-shadcn";  script="./scripts/bootstrap_vite_tailwind_shadcn.sh" ;; \
	    nextjs) target="bootstrap-nextjs-tailwind-shadcn"; script="./scripts/bootstrap_nextjs_tailwind_shadcn.sh" ;; \
	    *) echo "Error: STACK must be vite or nextjs (got '\''$$stack'\'')." >&2; exit 1 ;; \
	  esac; \
	  if [[ ! -x "$$script" ]]; then \
	    echo "Error: $$script not found or not executable." >&2; exit 1; \
	  fi; \
	  echo "▶ Running $$target with APP='\''$$app'\'' PM='\''$$pm'\''"; \
	  "$$script" "$$app" "$$pm" \
	'

# Non-interactive, explicit Vite bootstrap
bootstrap-vite-tailwind-shadcn:
	./scripts/bootstrap_vite_tailwind_shadcn.sh $(APP) $(PM)

# Non-interactive, explicit Next.js bootstrap
bootstrap-nextjs-tailwind-shadcn:
	./scripts/bootstrap_nextjs_tailwind_shadcn.sh $(APP) $(PM)
