# Bare metal: Homebrew Ruby 3.4.5, SQLite in $XDG_STATE_HOME/agentic-rails.
# Use gmake.
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
RUBY_BIN ?= /opt/homebrew/opt/ruby/bin
export PATH := $(HOME)/.gem/ruby/3.4.0/bin:$(RUBY_BIN):$(PATH)
PORT ?= 4900
STATE := $(or $(XDG_STATE_HOME),$(HOME)/.local/state)/agentic-rails

.PHONY: help deps db reset serve test check
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
