# Bare metal: Ruby 3.3.8 pinned by asdf (.tool-versions), SQLite in $XDG_STATE_HOME/agentic-rails.
# Use gmake.
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
export PATH := $(HOME)/.asdf/shims:$(PATH)
PORT ?= 4900
STATE := $(or $(XDG_STATE_HOME),$(HOME)/.local/state)/agentic-rails

.PHONY: help deps db reset serve test check report
help: ## This list
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-8s %s\n", $$1, $$2}'
deps: ## Install gems into vendor/bundle
	bundle config set --local path vendor/bundle >/dev/null
	bundle install --quiet
db: deps ## Migrate and seed the development database (idempotent)
	bin/rails db:prepare db:seed
reset: deps ## Drop, recreate and seed: the known starting state for e2e runs
	bin/rails db:drop db:create db:migrate db:seed
serve: db ## Serve on PORT (default 4900); the access log is teed into the state dir
	mkdir -p $(STATE)
	bin/rails server -p $(PORT) -b 127.0.0.1 2>&1 | tee -a $(STATE)/server-$(PORT).log
test: deps ## Model and controller tests
	bin/rails test
check: test ## What CI runs (for now)
report: ## Spans in the last MINUTES (default 60) of the data dir; exits 1 on a problem or 0 traces
	bin/report --data $(STATE) --minutes $(or $(MINUTES),60)
