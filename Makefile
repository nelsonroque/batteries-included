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
	@set -euo pipefail; \
	STACK_IN='$(STACK)'; APP_IN='$(APP)'; PM_IN='$(PM)'; OPENAPI_IN='$(OPENAPI)'; \
	\
	if [[ -z "$$STACK_IN" || "$$STACK_IN" == "ask" || "$$STACK_IN" == "-" ]]; then \
	  echo "Choose stack:"; \
	  echo "  1) vite                 – Vite + React + TS + Tailwind v4 + shadcn/ui"; \
	  echo "  2) nextjs               – Next.js + TS + Tailwind v4 + shadcn/ui"; \
	  echo "  3) nextjs-api-client    – Next.js + Tailwind + shadcn/ui + generated OpenAPI client"; \
	  echo "  4) auth-supabase        – Next.js + Tailwind + shadcn/ui + Supabase Auth"; \
	  echo "  5) api-client-openapi   – Standalone TS library from OpenAPI (openapi-fetch)"; \
	  read -rp "Enter choice [1-5]: " choice; \
	  case "$$choice" in \
	    1) STACK_IN="vite" ;; \
	    2) STACK_IN="nextjs" ;; \
	    3) STACK_IN="nextjs-api-client" ;; \
	    4) STACK_IN="auth-supabase" ;; \
	    5) STACK_IN="api-client-openapi" ;; \
	    *) echo "Error: invalid choice." >&2; exit 1 ;; \
	  esac; \
	fi; \
	\
	if [[ -z "$$APP_IN" || "$$APP_IN" == "my-app" ]]; then \
	  read -rp "Enter app name [my-app]: " in_app; APP_IN="$${in_app:-$$APP_IN}"; \
	fi; \
	if [[ -z "$$PM_IN" || "$$PM_IN" == "ask" || "$$PM_IN" == "-" ]]; then \
	  read -rp "Enter package manager (npm/pnpm) [npm]: " in_pm; PM_IN="$${in_pm:-npm}"; \
	fi; \
	case "$$PM_IN" in npm|pnpm) ;; *) echo "Error: PM must be npm or pnpm (got '\''$$PM_IN'\'')." >&2; exit 1 ;; esac; \
	\
	if [[ "$$STACK_IN" == "nextjs-api-client" || "$$STACK_IN" == "api-client-openapi" ]]; then \
	  if [[ -z "$$OPENAPI_IN" ]]; then \
	    read -rp "Enter OpenAPI URL or path (leave blank to skip generation now): " in_openapi; \
	    OPENAPI_IN="$$in_openapi"; \
	  fi; \
	fi; \
	\
	case "$$STACK_IN" in \
	  vite)                TARGET="bootstrap-vite-tailwind-shadcn" ;; \
	  nextjs)              TARGET="bootstrap-nextjs-tailwind-shadcn" ;; \
	  nextjs-api-client)   TARGET="bootstrap-nextjs-api-client" ;; \
	  auth-supabase)       TARGET="bootstrap-auth-supabase" ;; \
	  api-client-openapi)  TARGET="bootstrap-api-client-openapi" ;; \
	  *) echo "Error: unknown STACK '\''$$STACK_IN'\''." >&2; exit 1 ;; \
	esac; \
	\
	echo "▶ make $$TARGET APP='\$$APP_IN' PM='\$$PM_IN'$${OPENAPI_IN:+ OPENAPI='\$$OPENAPI_IN'}"; \
	$(MAKE) --no-print-directory $$TARGET APP="$$APP_IN" PM="$$PM_IN" OPENAPI="$$OPENAPI_IN"

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

gen-openapi-lib:
	make bootstrap STACK=nextjs-api-client \
	APP=m2c2-ts \
	PM=npm \
	OPENAPI=https://api.m2c2kit.com/openapi.json

	cd m2c2-ts
	OPENAPI=https://api.m2c2kit.com/openapi.json npm run generate:api


# ---- Config -------------------------------------------------
PYTHON ?= uv
PKG    ?= bootstrapper          # your package/distribution name
DIST   ?= dist

# ---- Helpers ------------------------------------------------
.PHONY: deps clean

# With uv we can run build/twine ad-hoc via uvx, so deps can be a no-op.
deps:
	@echo "Using uvx for ephemeral tooling (no deps to install)."

clean:
	rm -rf $(DIST) *.egg-info .pytest_cache .ruff_cache build

# ---- Step 4: Install locally (editable) ---------------------
.PHONY: install-local
install-local:
	$(PYTHON) pip install -e .

# Optional: uninstall
.PHONY: uninstall-local
uninstall-local:
	-$(PYTHON) pip uninstall -y $(PKG)

# ---- Step 5: Build & Publish -------------------------------
# Build (sdist + wheel) using the 'build' package via uvx
.PHONY: build
build: clean deps
	uvx --from build pyproject-build

# Test upload to TestPyPI (recommended)
.PHONY: publish-test
publish-test: build
	uvx twine upload --repository testpypi $(DIST)/*

# Publish to PyPI
.PHONY: publish
publish: build
	uvx twine upload $(DIST)/*
