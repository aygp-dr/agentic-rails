# Universal Makefile for Agentic Rails
# Works on FreeBSD, macOS, and Linux
# Uses sentinel files to track task completion

# Detect OS
UNAME_S := $(shell uname -s)
UNAME_R := $(shell uname -r)
UNAME_M := $(shell uname -m)

# Color output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
PURPLE := \033[0;35m
CYAN := \033[0;36m
WHITE := \033[1;37m
NC := \033[0m # No Color

# Platform-specific settings
ifeq ($(UNAME_S),FreeBSD)
	MAKE := gmake
	PKG_MANAGER := pkg
	PKG_INSTALL := pkg install -y
	STAT_CMD := stat -f %m
else ifeq ($(UNAME_S),Darwin)
	MAKE := make
	PKG_MANAGER := brew
	PKG_INSTALL := brew install
	STAT_CMD := stat -f %m
else
	MAKE := make
	PKG_MANAGER := apt
	PKG_INSTALL := apt-get install -y
	STAT_CMD := stat -c %Y
endif

# Project settings
RAILS_ENV ?= development
RUBY_VERSION := 3.3.0
NODE_VERSION := 20
POSTGRES_VERSION := 15
REDIS_VERSION := 7

# Sentinel directory for tracking completed tasks
SENTINEL_DIR := .make-sentinels
SENTINELS := $(SENTINEL_DIR)/.keep

# Default target
.PHONY: all
all: setup

# Create sentinel directory
$(SENTINEL_DIR):
	@mkdir -p $(SENTINEL_DIR)

# Help target
.PHONY: help
help:
	@echo "$(CYAN)Agentic Rails - Universal Makefile$(NC)"
	@echo "$(WHITE)Platform:$(NC) $(UNAME_S) $(UNAME_R) $(UNAME_M)"
	@echo "$(WHITE)Package Manager:$(NC) $(PKG_MANAGER)"
	@echo ""
	@echo "$(YELLOW)Core Targets:$(NC)"
	@echo "  $(GREEN)make setup$(NC)          - Complete development setup"
	@echo "  $(GREEN)make deps$(NC)           - Install all dependencies"
	@echo "  $(GREEN)make db$(NC)             - Setup database"
	@echo "  $(GREEN)make test$(NC)           - Run test suite"
	@echo "  $(GREEN)make server$(NC)         - Start development server"
	@echo "  $(GREEN)make console$(NC)        - Start Rails console"
	@echo ""
	@echo "$(YELLOW)Development:$(NC)"
	@echo "  $(GREEN)make dev$(NC)            - Start all services (tmux)"
	@echo "  $(GREEN)make monitor$(NC)        - Start monitoring dashboard"
	@echo "  $(GREEN)make lint$(NC)           - Run code linters"
	@echo "  $(GREEN)make format$(NC)         - Auto-format code"
	@echo ""
	@echo "$(YELLOW)Docker:$(NC)"
	@echo "  $(GREEN)make docker-build$(NC)   - Build Docker image"
	@echo "  $(GREEN)make docker-up$(NC)      - Start with Docker Compose"
	@echo "  $(GREEN)make docker-down$(NC)    - Stop Docker containers"
	@echo ""
	@echo "$(YELLOW)Maintenance:$(NC)"
	@echo "  $(GREEN)make clean$(NC)          - Remove generated files"
	@echo "  $(GREEN)make reset$(NC)          - Reset database"
	@echo "  $(GREEN)make update$(NC)         - Update dependencies"
	@echo ""
	@echo "$(YELLOW)CI/CD:$(NC)"
	@echo "  $(GREEN)make ci$(NC)             - Run CI checks"
	@echo "  $(GREEN)make deploy$(NC)         - Deploy to production"

# === DEPENDENCY MANAGEMENT ===

# System dependencies check
$(SENTINEL_DIR)/system-deps: $(SENTINEL_DIR)
	@echo "$(BLUE)Checking system dependencies...$(NC)"
	@command -v ruby >/dev/null 2>&1 || (echo "$(RED)Ruby not found$(NC)" && exit 1)
	@command -v node >/dev/null 2>&1 || (echo "$(RED)Node.js not found$(NC)" && exit 1)
	@command -v psql >/dev/null 2>&1 || (echo "$(RED)PostgreSQL not found$(NC)" && exit 1)
	@command -v redis-cli >/dev/null 2>&1 || (echo "$(RED)Redis not found$(NC)" && exit 1)
	@echo "$(GREEN)✓ All system dependencies present$(NC)"
	@touch $@

# Ruby dependencies
$(SENTINEL_DIR)/ruby-deps: $(SENTINEL_DIR)/system-deps Gemfile Gemfile.lock
	@echo "$(BLUE)Installing Ruby dependencies...$(NC)"
	@bundle check || bundle install
	@echo "$(GREEN)✓ Ruby dependencies installed$(NC)"
	@touch $@

# Node dependencies
$(SENTINEL_DIR)/node-deps: $(SENTINEL_DIR)/system-deps package.json
	@echo "$(BLUE)Installing Node dependencies...$(NC)"
	@if [ -f yarn.lock ]; then \
		yarn install; \
	elif [ -f package-lock.json ]; then \
		npm ci; \
	else \
		npm install; \
	fi
	@echo "$(GREEN)✓ Node dependencies installed$(NC)"
	@touch $@

# All dependencies
.PHONY: deps
deps: $(SENTINEL_DIR)/ruby-deps $(SENTINEL_DIR)/node-deps
	@echo "$(GREEN)✓ All dependencies installed$(NC)"

# === DATABASE MANAGEMENT ===

# Database setup
$(SENTINEL_DIR)/db-created: $(SENTINEL_DIR)/system-deps
	@echo "$(BLUE)Creating database...$(NC)"
	@bundle exec rails db:create RAILS_ENV=$(RAILS_ENV) || true
	@echo "$(GREEN)✓ Database created$(NC)"
	@touch $@

# Database migrations
$(SENTINEL_DIR)/db-migrated: $(SENTINEL_DIR)/db-created $(shell find db/migrate -type f 2>/dev/null)
	@echo "$(BLUE)Running migrations...$(NC)"
	@bundle exec rails db:migrate RAILS_ENV=$(RAILS_ENV)
	@echo "$(GREEN)✓ Migrations completed$(NC)"
	@touch $@

# Database seeds
$(SENTINEL_DIR)/db-seeded: $(SENTINEL_DIR)/db-migrated db/seeds.rb
	@echo "$(BLUE)Seeding database...$(NC)"
	@bundle exec rails db:seed RAILS_ENV=$(RAILS_ENV)
	@echo "$(GREEN)✓ Database seeded$(NC)"
	@touch $@

# Complete database setup
.PHONY: db
db: $(SENTINEL_DIR)/db-seeded
	@echo "$(GREEN)✓ Database ready$(NC)"

# === TESTING ===

# Run tests
.PHONY: test
test: $(SENTINEL_DIR)/ruby-deps $(SENTINEL_DIR)/db-migrated
	@echo "$(BLUE)Running tests...$(NC)"
	@RAILS_ENV=test bundle exec rails test
	@echo "$(GREEN)✓ Tests completed$(NC)"

# Run system tests
.PHONY: test-system
test-system: $(SENTINEL_DIR)/ruby-deps $(SENTINEL_DIR)/db-migrated
	@echo "$(BLUE)Running system tests...$(NC)"
	@RAILS_ENV=test bundle exec rails test:system
	@echo "$(GREEN)✓ System tests completed$(NC)"

# Run all tests with coverage
.PHONY: test-all
test-all: test test-system
	@echo "$(GREEN)✓ All tests completed$(NC)"

# === DEVELOPMENT ===

# Start Rails server
.PHONY: server
server: deps db
	@echo "$(CYAN)Starting Rails server on http://localhost:3000$(NC)"
	@bundle exec rails server

# Start Rails console
.PHONY: console
console: deps db
	@echo "$(CYAN)Starting Rails console...$(NC)"
	@bundle exec rails console

# Start development environment with tmux
.PHONY: dev
dev: deps db
	@echo "$(CYAN)Starting development environment...$(NC)"
	@if command -v tmux >/dev/null 2>&1; then \
		tmux new-session -s agentic-rails -d; \
		tmux source-file .tmux.conf; \
		tmux source-file .tmux/dev-layout.conf; \
		tmux attach-session -t agentic-rails; \
	else \
		echo "$(YELLOW)tmux not found, starting server only$(NC)"; \
		$(MAKE) server; \
	fi

# Start monitoring dashboard
.PHONY: monitor
monitor: deps
	@echo "$(CYAN)Starting monitoring dashboard...$(NC)"
	@ruby bin/monitor

# === CODE QUALITY ===

# Run linters
.PHONY: lint
lint: $(SENTINEL_DIR)/ruby-deps
	@echo "$(BLUE)Running linters...$(NC)"
	@bundle exec rubocop
	@bundle exec brakeman -q
	@bundle exec bundler-audit check --update
	@echo "$(GREEN)✓ Linting completed$(NC)"

# Auto-format code
.PHONY: format
format: $(SENTINEL_DIR)/ruby-deps
	@echo "$(BLUE)Formatting code...$(NC)"
	@bundle exec rubocop -a
	@echo "$(GREEN)✓ Formatting completed$(NC)"

# === DOCKER ===

# Build Docker image
.PHONY: docker-build
docker-build:
	@echo "$(BLUE)Building Docker image...$(NC)"
	@docker build -t agentic-rails:latest .
	@echo "$(GREEN)✓ Docker image built$(NC)"

# Start with Docker Compose
.PHONY: docker-up
docker-up:
	@echo "$(BLUE)Starting Docker containers...$(NC)"
	@docker-compose up -d
	@echo "$(GREEN)✓ Containers started$(NC)"
	@echo "$(CYAN)Application: http://localhost:3000$(NC)"
	@echo "$(CYAN)Monitoring: http://localhost:3001$(NC)"

# Stop Docker containers
.PHONY: docker-down
docker-down:
	@echo "$(BLUE)Stopping Docker containers...$(NC)"
	@docker-compose down
	@echo "$(GREEN)✓ Containers stopped$(NC)"

# === MAINTENANCE ===

# Clean generated files and sentinels
.PHONY: clean
clean:
	@echo "$(BLUE)Cleaning generated files...$(NC)"
	@rm -rf $(SENTINEL_DIR)
	@rm -rf tmp/cache tmp/pids tmp/sockets
	@rm -rf log/*.log
	@rm -rf public/assets
	@echo "$(GREEN)✓ Cleaned$(NC)"

# Reset database
.PHONY: reset
reset:
	@echo "$(YELLOW)Resetting database...$(NC)"
	@bundle exec rails db:drop db:create db:migrate db:seed
	@rm -f $(SENTINEL_DIR)/db-*
	@echo "$(GREEN)✓ Database reset$(NC)"

# Update dependencies
.PHONY: update
update:
	@echo "$(BLUE)Updating dependencies...$(NC)"
	@bundle update
	@yarn upgrade
	@rm -f $(SENTINEL_DIR)/ruby-deps $(SENTINEL_DIR)/node-deps
	@$(MAKE) deps
	@echo "$(GREEN)✓ Dependencies updated$(NC)"

# === CI/CD ===

# Run CI checks
.PHONY: ci
ci: deps db lint test
	@echo "$(GREEN)✓ CI checks passed$(NC)"

# Deploy to production
.PHONY: deploy
deploy:
	@echo "$(BLUE)Deploying to production...$(NC)"
	@ruby bin/deploy production
	@echo "$(GREEN)✓ Deployment completed$(NC)"

# === SETUP ===

# Complete development setup
.PHONY: setup
setup: $(SENTINEL_DIR)
	@echo "$(PURPLE)════════════════════════════════════════$(NC)"
	@echo "$(PURPLE)    Agentic Rails Development Setup     $(NC)"
	@echo "$(PURPLE)════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(WHITE)Platform:$(NC) $(UNAME_S) $(UNAME_R)"
	@echo "$(WHITE)Ruby:$(NC) $(shell ruby --version 2>/dev/null || echo 'Not installed')"
	@echo "$(WHITE)Node:$(NC) $(shell node --version 2>/dev/null || echo 'Not installed')"
	@echo ""
	@$(MAKE) deps
	@$(MAKE) db
	@echo ""
	@echo "$(PURPLE)════════════════════════════════════════$(NC)"
	@echo "$(GREEN)✓ Setup complete!$(NC)"
	@echo ""
	@echo "$(WHITE)Next steps:$(NC)"
	@echo "  $(CYAN)make dev$(NC)      - Start development environment"
	@echo "  $(CYAN)make test$(NC)     - Run tests"
	@echo "  $(CYAN)make help$(NC)     - Show all commands"
	@echo ""

# === SPECIAL TARGETS ===

# Install system dependencies (platform-specific)
.PHONY: install-deps
install-deps:
	@echo "$(BLUE)Installing system dependencies for $(UNAME_S)...$(NC)"
ifeq ($(UNAME_S),FreeBSD)
	@$(PKG_INSTALL) ruby33 rubygem-bundler node20 postgresql15-client redis
else ifeq ($(UNAME_S),Darwin)
	@$(PKG_INSTALL) rbenv ruby-build postgresql@15 redis node
else
	@$(PKG_INSTALL) ruby-full nodejs postgresql-client redis-server
endif
	@echo "$(GREEN)✓ System dependencies installed$(NC)"

# Check versions
.PHONY: versions
versions:
	@echo "$(CYAN)Installed versions:$(NC)"
	@echo "Ruby:       $$(ruby --version 2>/dev/null || echo 'Not found')"
	@echo "Bundler:    $$(bundle --version 2>/dev/null || echo 'Not found')"
	@echo "Rails:      $$(rails --version 2>/dev/null || echo 'Not found')"
	@echo "Node:       $$(node --version 2>/dev/null || echo 'Not found')"
	@echo "PostgreSQL: $$(psql --version 2>/dev/null || echo 'Not found')"
	@echo "Redis:      $$(redis-cli --version 2>/dev/null || echo 'Not found')"
	@echo "Docker:     $$(docker --version 2>/dev/null || echo 'Not found')"

.PHONY: check-sentinels
check-sentinels:
	@echo "$(CYAN)Sentinel status:$(NC)"
	@for sentinel in $(SENTINEL_DIR)/*; do \
		if [ -f "$$sentinel" ]; then \
			basename="$$(basename $$sentinel)"; \
			echo "$(GREEN)✓$(NC) $$basename"; \
		fi \
	done

# Prevent make from trying to remake the Makefile
Makefile: ;