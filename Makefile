# Makefile for project bootstrapping with Tailwind v4 + shadcn/ui
#
# Variables (can be provided non-interactively, e.g., `make bootstrap STACK=nextjs-api-client PM=pnpm APP=my-app OPENAPI=...`):
#   APP      – project name (default: my-app)
#   STACK    – one of: vite | nextjs | nextjs-api-client | auth-supabase | api-client-openapi
#   PM       – npm | pnpm (default: npm)
#   OPENAPI  – URL or file path for OpenAPI spec (only used by *-api-client targets)
#
# Scripts expected:
#   ./scripts/bootstrap_vite_tailwind_shadcn.sh
#   ./scripts/bootstrap_nextjs_tailwind_shadcn.sh
#   ./scripts/bootstrap_nextjs_api_client.sh
#   ./scripts/bootstrap_api_client_openapi.sh
#   ./scripts/bootstrap_auth_supabase.sh
#
# Examples:
#   make bootstrap                                   # prompts for anything not provided
#   make bootstrap STACK=vite APP=demo
#   make bootstrap STACK=api-client-openapi OPENAPI=https://api.example.com/openapi.json
#   make bootstrap-nextjs-api-client APP=dashboard OPENAPI=./openapi.json PM=pnpm

SHELL := /usr/bin/env bash

APP ?= my-app
PM  ?= npm

.PHONY: \
  bootstrap \
  bootstrap-vite-tailwind-shadcn \
  bootstrap-nextjs-tailwind-shadcn \
  bootstrap-api-client-openapi \
  bootstrap-auth-supabase \
  bootstrap-nextjs-api-client

# Interactive meta-target: prompts for STACK/APP/PM (and OPENAPI if needed),
# then dispatches to the correct script.
bootstrap:
	@bash -eu -o pipefail -c '\
	  stack="${STACK:-}"; \
	  app="${APP:-my-app}"; \
	  pm="${PM:-npm}"; \
	  openapi="${OPENAPI:-}"; \
	  \
	  if [[ -z "$$stack" || "$$stack" = "ask" || "$$stack" = "-" ]]; then \
	    echo "Choose stack:"; \
	    echo "  1) vite                 – Vite + React + TS + Tailwind v4 + shadcn/ui"; \
	    echo "  2) nextjs               – Next.js + TS + Tailwind v4 + shadcn/ui"; \
	    echo "  3) nextjs-api-client    – Next.js + Tailwind + shadcn/ui + generated OpenAPI client"; \
	    echo "  4) auth-supabase        – Next.js + Tailwind + shadcn/ui + Supabase Auth"; \
	    echo "  5) api-client-openapi   – Standalone TS library from OpenAPI (openapi-fetch)"; \
	    read -rp "Enter choice [1-5]: " choice; \
	    case "$$choice" in \
	      1) stack="vite" ;; \
	      2) stack="nextjs" ;; \
	      3) stack="nextjs-api-client" ;; \
	      4) stack="auth-supabase" ;; \
	      5) stack="api-client-openapi" ;; \
	      *) echo "Error: invalid choice." >&2; exit 1 ;; \
	    esac; \
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
	  # Determine target & script; prompt for OPENAPI when needed \
	  case "$$stack" in \
	    vite)                target="bootstrap-vite-tailwind-shadcn";        script="./scripts/bootstrap_vite_tailwind_shadcn.sh" ;; \
	    nextjs)              target="bootstrap-nextjs-tailwind-shadcn";      script="./scripts/bootstrap_nextjs_tailwind_shadcn.sh" ;; \
	    nextjs-api-client)   target="bootstrap-nextjs-api-client";           script="./scripts/bootstrap_nextjs_api_client.sh" ;; \
	    auth-supabase)       target="bootstrap-auth-supabase";               script="./scripts/bootstrap_auth_supabase.sh" ;; \
	    api-client-openapi)  target="bootstrap-api-client-openapi";          script="./scripts/bootstrap_api_client_openapi.sh" ;; \
	    *) echo "Error: STACK must be one of: vite | nextjs | nextjs-api-client | auth-supabase | api-client-openapi (got '\''$$stack'\'')." >&2; exit 1 ;; \
	  esac; \
	  if [[ "$$stack" = "nextjs-api-client" || "$$stack" = "api-client-openapi" ]]; then \
	    if [[ -z "$$openapi" ]]; then \
	      read -rp "Enter OpenAPI URL or path (leave blank to skip generation now): " in_openapi; \
	      openapi="$$in_openapi"; \
	    fi; \
	  fi; \
	  if [[ ! -f "$$script" ]]; then \
	    echo "Error: $$script not found." >&2; exit 1; \
	  fi; \
	  if [[ ! -x "$$script" ]]; then \
	    echo "Note: $$script is not executable. Attempting to chmod +x…"; chmod +x "$$script" || true; \
	  fi; \
	  echo "▶ Running $$target with APP='\''$$app'\'' PM='\''$$pm'\''$${openapi:+ OPENAPI='\''$$openapi'\''}"; \
	  if [[ "$$stack" = "nextjs-api-client" || "$$stack" = "api-client-openapi" ]]; then \
	    "$$script" "$$app" "$$pm" "$$openapi"; \
	  else \
	    "$$script" "$$app" "$$pm"; \
	  fi; \
	'

# ---- Non-interactive explicit targets ---------------------------------------

# Vite + React + TS + Tailwind v4 + shadcn/ui
bootstrap-vite-tailwind-shadcn:
	./scripts/bootstrap_vite_tailwind_shadcn.sh $(APP) $(PM)

# Next.js + TS + Tailwind v4 + shadcn/ui
bootstrap-nextjs-tailwind-shadcn:
	./scripts/bootstrap_nextjs_tailwind_shadcn.sh $(APP) $(PM)

# Standalone TS API client from an OpenAPI URL/file (library)
bootstrap-api-client-openapi:
	./scripts/bootstrap_api_client_openapi.sh $(APP) $(PM) $(OPENAPI)

# Next.js + Tailwind v4 + shadcn/ui + Supabase Auth (magic link)
bootstrap-auth-supabase:
	./scripts/bootstrap_auth_supabase.sh $(APP) $(PM)

# Next.js app with in-repo OpenAPI client generation
bootstrap-nextjs-api-client:
	./scripts/bootstrap_nextjs_api_client.sh $(APP) $(PM) $(OPENAPI)
