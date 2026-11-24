# Review instructions

What a review of agentic-rails should flag, at what severity, and what to skip. The author's steps are in
`AGENTS.md`. A change to these rules goes in a PR of its own.

## What Important means here

Reserve Important for findings that would:
- get money or stock wrong (a total off by a cent, stock below 0, an order placed twice for one key);
- put SQL text, a literal or a bind value in a span;
- lose a request's span or `traceparent`, or attribute it to the wrong runner;
- let a test write to the owner's state dir;
- expose a dev endpoint or a local path outside development;
- commit a personal detail or the name of another private project;
- break `gmake check`.

Style, naming and refactoring are Nit at most.

## Cap the nits

Report at most five Nits per review.

## Do not report

- `Gemfile.lock`, `db/schema.rb`, `vendor/`, `log/`, `tmp/`: generated or local.
- `.meta/*.org` prose, unless it contradicts the code or the README.
- Rails scaffolding left as generated (`config/environments/*`, `bin/rails`, `bin/rake`), unless the change touched it.

## Always check

Shop
- Money is integer cents end to end: no floats in arithmetic, only in formatting (`Order#total`).
- Stock is checked and taken inside the checkout transaction, under `lock!`; a cart quantity is refused (422)
  beyond stock, and stock never goes below 0.
- The same `idempotency_key` returns the same order (200, not 201) and takes stock once, including two
  requests racing on one key.
- The seeds keep their boundaries: one pet with stock 1, one with stock 0 (`db/seeds.rb`, README).

Telemetry
- `Telemetry::Middleware` stays first in the stack. Every response carries `traceparent`; a valid incoming one
  is continued, a malformed one starts a new trace.
- A DB span carries `db.query.summary` (`SELECT pets`), never SQL text or values. Transaction and schema
  statements (`BEGIN`, `PRAGMA`, …) are not spans.
- Runner keys come from `baggage` and `?ff=`, baggage winning key by key. `app.driver` is one of the listed
  values or `unknown`; other values must match `[a-z0-9-]{1,48}` or are dropped.
- A new kind of request from the page (fetch, Turbo, WebMCP tool) sends `traceparent` and the runner
  (`app/javascript/telemetry.js`).
- An order records `driver` and `trace_id`, and its checkout span carries `app.order.id`.
- `bin/report` exits 1 on any problem and on a window with 0 traces; a new problem kind is listed in the README.

Flags
- A flag is in `config/flags.yml` first, and `lib/flags/registry.rb` validates it: name `[a-z0-9-]`, stage
  a..e, default on only from stage d.
- The OpenFeature provider tells a feature never set (registry default, `DEFAULT`) from one turned off.
- Flags use the memory adapter: nothing persists to the checkout or the state dir.

Dev and safety
- Dev endpoints answer 204 outside development (`Api::DevController`).
- Tests never write to the owner's state dir: `test/test_helper.rb` sets `XDG_STATE_HOME` to a temp dir, and
  telemetry tests use `TelemetryHelpers`.
- No Python in repo code. Make targets assume gmake.
- This repo is public. Committed text (code, docs, commit messages, PR bodies) names other projects by role
  ("the source project", "the hub spec"), never by repo; no home paths, emails or user names.

Tests
- A fix comes with a test that fails without it.
- A check over a whole file for a short value can match ids or timestamps by chance; look only where the value
  could leak (`test/telemetry/db_spans_test.rb`).

## Evidence

A behaviour claim cites `file:line` in the source, or a command and its output; not an inference from a name.
Mark anything not run as unconfirmed.
