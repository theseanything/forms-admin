# AGENTS.md

## Cursor Cloud specific instructions

### Overview

This is **GOV.UK Forms Admin** — a Ruby on Rails 8.1 application for creating, managing, and publishing government forms. It uses PostgreSQL, Vite for frontend asset building, and the GOV.UK Design System.

### Prerequisites

- **Ruby 3.4.8** — installed at `/usr/local/ruby-3.4.8/bin` (ensure this is on PATH)
- **Node.js 22.x** — for Vite and JS tests
- **PostgreSQL 16** — running on localhost:5432, user `postgres`, password `postgres`

### Running the app

```bash
bin/dev
```

This starts both Rails (port 3000) and Vite dev server (port 3036) via foreman. In development, authentication is mocked (`mock_gds_sso`) so you are automatically logged in.

### Running tests

- **Ruby tests:** `bundle exec rspec` (5269 specs, ~7 min)
- **JS tests:** `npm run test` (Vitest, 129 specs, ~4s)
- **Full rake (lint + tests):** `bundle exec rake`

### Linting

- **Ruby:** `bundle exec rubocop -A`
- **JS:** `npm run lint`
- **i18n normalization:** `bundle exec i18n-tasks normalize`

### Key caveats

- The app connects to `forms-api` (localhost:9292) at runtime — but all tests stub HTTP calls via WebMock, so no external services are needed for the test suite.
- PostgreSQL must be started before running any Rails commands: `sudo pg_ctlcluster 16 main start`
- System/feature specs require Chrome/Chromium (headless by default). Chromium is installed at the system level.
- The `bin/setup` script is idempotent and runs `bundle install`, `db:prepare`, `npm install`, and `vite build`.
- Database config expects user `postgres` with password `postgres` connecting via TCP to localhost.
