# Installation Guide - Agentic Rails

This guide provides platform-specific installation instructions for Agentic Rails.

## Table of Contents
- [Quick Start](#quick-start)
- [FreeBSD](#freebsd)
- [macOS](#macos)
- [Linux](#linux)
- [Docker (Universal)](#docker-universal)
- [Troubleshooting](#troubleshooting)

## Quick Start

The fastest way to get started:

```bash
# 1. Clone the repository
git clone https://github.com/aygp-dr/agentic-rails.git
cd agentic-rails

# 2. Run onboarding script
./bin/onboard

# 3. Setup with Make
make setup

# 4. Start development
make dev
```

## FreeBSD

### System Requirements
- FreeBSD 13.0 or later
- 4GB RAM minimum
- 10GB free disk space

### Installation Steps

#### 1. Install System Dependencies

```bash
# Update packages
sudo pkg update

# Install required packages
sudo pkg install -y \
  ruby33 \
  rubygem-bundler \
  node20 \
  npm-node20 \
  postgresql15-server \
  postgresql15-client \
  redis \
  git \
  gmake \
  tmux

# Install development tools
sudo pkg install -y \
  autoconf \
  automake \
  libtool \
  pkgconf \
  libffi \
  readline \
  libyaml \
  libxml2 \
  libxslt
```

#### 2. Setup PostgreSQL

```bash
# Enable PostgreSQL
sudo sysrc postgresql_enable="YES"

# Initialize database
sudo service postgresql initdb

# Start PostgreSQL
sudo service postgresql start

# Create user
sudo -u postgres createuser -s $USER
```

#### 3. Setup Redis

```bash
# Enable Redis
sudo sysrc redis_enable="YES"

# Start Redis
sudo service redis start
```

#### 4. Install rbenv (Recommended)

```bash
# Install rbenv and ruby-build
sudo pkg install rbenv ruby-build

# Add to shell
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

# Install Ruby
rbenv install 3.3.0
rbenv global 3.3.0
```

#### 5. Clone and Setup Project

```bash
# Clone repository
git clone https://github.com/aygp-dr/agentic-rails.git
cd agentic-rails

# Install dependencies
bundle install
yarn install

# Setup database
gmake db

# Run tests
gmake test

# Start server
gmake server
```

### FreeBSD-Specific Notes

- Always use `gmake` instead of `make`
- PostgreSQL runs on port 5432 by default
- Redis runs on port 6379 by default
- Use `service` command to manage services

## macOS

### System Requirements
- macOS 11 (Big Sur) or later
- Xcode Command Line Tools
- 8GB RAM recommended
- 10GB free disk space

### Installation Steps

#### 1. Install Xcode Command Line Tools

```bash
xcode-select --install
```

#### 2. Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 3. Install System Dependencies

```bash
# Install required packages
brew install \
  rbenv \
  ruby-build \
  postgresql@15 \
  redis \
  node@20 \
  yarn \
  tmux \
  git

# Start services
brew services start postgresql@15
brew services start redis
```

#### 4. Setup Ruby with rbenv

```bash
# Initialize rbenv
echo 'eval "$(rbenv init -)"' >> ~/.zshrc
source ~/.zshrc

# Install Ruby
rbenv install 3.3.0
rbenv global 3.3.0

# Install bundler
gem install bundler
```

#### 5. Clone and Setup Project

```bash
# Clone repository
git clone https://github.com/aygp-dr/agentic-rails.git
cd agentic-rails

# Run setup
make setup

# Start development
make dev
```

### macOS-Specific Notes

- Use `brew services` to manage services
- Default shell is zsh (use ~/.zshrc for configuration)
- May need to allow terminal apps in Security & Privacy settings

## Linux

### Ubuntu/Debian

#### 1. Install System Dependencies

```bash
# Update packages
sudo apt update
sudo apt upgrade -y

# Install dependencies
sudo apt install -y \
  curl \
  git \
  build-essential \
  libssl-dev \
  libreadline-dev \
  zlib1g-dev \
  libpq-dev \
  postgresql \
  postgresql-contrib \
  redis-server \
  tmux

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install Yarn
npm install -g yarn
```

#### 2. Install Ruby with rbenv

```bash
# Clone rbenv
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

# Add to PATH
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

# Install Ruby
rbenv install 3.3.0
rbenv global 3.3.0
```

#### 3. Setup Project

```bash
# Clone and setup
git clone https://github.com/aygp-dr/agentic-rails.git
cd agentic-rails
make setup
```

### Fedora/RHEL/CentOS

#### 1. Install System Dependencies

```bash
# Install development tools
sudo dnf groupinstall "Development Tools"

# Install dependencies
sudo dnf install -y \
  git \
  postgresql-server \
  postgresql-devel \
  redis \
  tmux \
  openssl-devel \
  readline-devel \
  zlib-devel

# Install Node.js 20
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
sudo dnf install -y nodejs
```

#### 2. Setup PostgreSQL

```bash
# Initialize PostgreSQL
sudo postgresql-setup --initdb

# Start services
sudo systemctl start postgresql
sudo systemctl enable postgresql
sudo systemctl start redis
sudo systemctl enable redis
```

### Arch Linux

#### 1. Install System Dependencies

```bash
# Update system
sudo pacman -Syu

# Install packages
sudo pacman -S \
  base-devel \
  ruby \
  postgresql \
  redis \
  nodejs \
  npm \
  yarn \
  tmux \
  git
```

## Docker (Universal)

Docker provides a consistent environment across all platforms.

### Prerequisites
- Docker Desktop (macOS/Windows) or Docker Engine (Linux)
- Docker Compose v2+
- 4GB RAM allocated to Docker

### Quick Start

```bash
# Clone repository
git clone https://github.com/aygp-dr/agentic-rails.git
cd agentic-rails

# Build and start containers
docker-compose up -d

# Setup database
docker-compose exec rails bundle exec rails db:setup

# Run tests
docker-compose exec rails bundle exec rails test

# Access application
open http://localhost:3000

# View logs
docker-compose logs -f rails
```

### Docker Commands

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Rebuild images
docker-compose build

# Run Rails console
docker-compose exec rails rails console

# Run shell in container
docker-compose exec rails bash

# Run tests
docker-compose exec rails make test

# View monitoring
open http://localhost:3001  # Grafana
open http://localhost:9090  # Prometheus
```

### Docker Profiles

```bash
# Simple setup (single container)
docker-compose --profile simple up

# Full setup (all services)
docker-compose up

# Development with monitoring
docker-compose up rails postgres redis prometheus grafana
```

## Troubleshooting

### Common Issues

#### Ruby Version Mismatch
```bash
# Check Ruby version
ruby --version

# Install correct version with rbenv
rbenv install 3.3.0
rbenv local 3.3.0
```

#### Bundle Install Fails
```bash
# Clear bundler cache
rm -rf vendor/bundle
rm Gemfile.lock

# Reinstall
bundle install
```

#### Database Connection Error
```bash
# Check PostgreSQL status
# FreeBSD
service postgresql status

# macOS
brew services list

# Linux
systemctl status postgresql

# Fix connection
createdb agentic_rails_development
```

#### Port Already in Use
```bash
# Find process using port 3000
lsof -i :3000

# Kill process
kill -9 <PID>

# Or use different port
rails server -p 3001
```

#### Permission Errors
```bash
# Fix permissions
sudo chown -R $USER:$USER .

# Reset file permissions
find . -type f -exec chmod 644 {} \;
find . -type d -exec chmod 755 {} \;
chmod +x bin/*
```

### Platform-Specific Issues

#### FreeBSD: gmake not found
```bash
# Install gmake
sudo pkg install gmake

# Create alias
alias make='gmake'
```

#### macOS: pg gem installation fails
```bash
# Set PostgreSQL config
bundle config build.pg --with-pg-config=/usr/local/opt/postgresql@15/bin/pg_config

# Reinstall
bundle install
```

#### Linux: Node version too old
```bash
# Remove old Node
sudo apt remove nodejs

# Install Node 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install nodejs
```

## Getting Help

- **Documentation**: [README.md](../README.md)
- **Issues**: [GitHub Issues](https://github.com/aygp-dr/agentic-rails/issues)
- **Progressive Commit Protocol**: [Guide](PROGRESSIVE_COMMIT_PROTOCOL_GUIDE.md)

## Verification

Run the onboarding script to verify your installation:

```bash
./bin/onboard
```

All checks should pass before proceeding with development.