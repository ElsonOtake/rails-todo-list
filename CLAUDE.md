# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Ruby on Rails 8.0.2 application using PostgreSQL as the database and modern Rails conventions including the Solid trilogy (Queue, Cache, Cable) for background processing, caching, and WebSockets.

## Essential Commands

### Development
```bash
# Initial setup (install dependencies, create database, etc.)
bin/setup

# Start development server
bin/rails server

# Rails console
bin/rails console

# Database operations
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
bin/rails db:drop
bin/rails db:reset

# Generate Rails components
bin/rails generate controller ControllerName
bin/rails generate model ModelName
bin/rails generate scaffold ResourceName
```

### Testing
```bash
# Run all tests (runs in parallel by default)
bin/rails test

# Run specific test file
bin/rails test test/models/user_test.rb

# Run system tests
bin/rails test:system

# Run tests with specific line number
bin/rails test test/models/user_test.rb:15
```

### Code Quality
```bash
# Run RuboCop linting (Rails Omakase style)
bin/rubocop

# Auto-fix RuboCop issues
bin/rubocop -A

# Security scanning
bin/brakeman
```

### Asset Management
```bash
# Manage JavaScript dependencies with import maps
bin/importmap pin package_name
bin/importmap unpin package_name

# Precompile assets for production
bin/rails assets:precompile
```

### Deployment (Kamal)
```bash
# Deploy to production
bin/kamal deploy

# Access production console
bin/kamal console

# View production logs
bin/kamal logs

# Access production database
bin/kamal dbc
```

## Architecture Overview

### Rails Stack
- **Rails 8.0.2** with Ruby 3.4.5
- **Database**: PostgreSQL with multi-database setup in production (primary, cache, queue, cable)
- **Frontend**: Hotwire (Turbo + Stimulus) with Import Maps for JavaScript
- **Background Jobs**: Solid Queue (runs in Puma process)
- **Caching**: Solid Cache (database-backed)
- **WebSockets**: Solid Cable (database-backed)
- **Assets**: Propshaft for asset pipeline
- **Deployment**: Docker-based with Kamal

### Directory Structure
```
app/
├── controllers/     # Request handling
├── models/         # Business logic and data
├── views/          # HTML templates (ERB)
├── helpers/        # View helpers
├── javascript/     # Stimulus controllers and JS
├── jobs/           # Background jobs (Solid Queue)
├── mailers/        # Email functionality
└── channels/       # WebSocket channels (Solid Cable)

config/
├── application.rb  # Main app configuration
├── routes.rb       # URL routing
├── database.yml    # Database configuration
├── credentials/    # Encrypted secrets
└── environments/   # Environment-specific settings

test/               # Minitest test suite
```

### Key Architectural Decisions

1. **Solid Trilogy**: Uses Rails 8's built-in Solid Queue, Cache, and Cable instead of Redis/Sidekiq
2. **Import Maps**: Native ES modules without bundling (no Webpack/esbuild)
3. **Hotwire-First**: Server-rendered HTML with Turbo and Stimulus for interactivity
4. **Docker Deployment**: Containerized with multi-stage builds via Kamal
5. **Modern Browsers Only**: Configured to support only modern browsers for enhanced features

### Database Configuration

- Development/Test: Single PostgreSQL database
- Production: Multi-database setup with separate databases for primary data, cache, queue, and cable
- Migrations apply to the primary database by default

### Testing Approach

- Framework: Minitest (Rails default)
- Parallel test execution enabled
- System tests with Capybara and Selenium
- Test files mirror app structure in `test/` directory

### Code Style

Follows Rails Omakase style guide via RuboCop. Key conventions:
- 2 spaces for indentation
- Double quotes for strings
- No trailing whitespace
- Rails best practices enforced

Always run `bin/rubocop` before committing code to ensure style compliance.