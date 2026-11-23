# agentic-rails

A small Rails pet shop used as a workshop for agentic, worktree-based development, where telemetry comes first.
It ports what jwalsh/gforth-hp48 built:
- named runners, and one trace id across every log;
- a log check that fails loudly;
- dev-only tool endpoints;
- Chrome WebMCP tools;
- Playwright and Bombadil end-to-end testing.

The port plan is `.meta/context-surfaces-port.org`.

Bare metal: Ruby 3.3.8 pinned by asdf (`.tool-versions`), Rails 8, SQLite. The development database lives in
`$XDG_STATE_HOME/agentic-rails/`, not in the checkout, so a worktree slot isolates its data by setting
`XDG_STATE_HOME`.

```sh
gmake serve          # migrate, seed, serve on 127.0.0.1:4900 (the review port)
gmake reset          # drop, recreate and seed: the known starting state for e2e runs
gmake test           # model and controller tests
```

The seeds are a fixed catalogue of 10 pets (`db/seeds.rb`), with stock chosen for boundaries:
- one pet with stock 1, which sells out on one checkout;
- one with stock 0, which can never be added;
- the rest plentiful.

| route | what |
|---|---|
| `GET /`, `/pets.json`, `/pets/:sku` | the catalogue |
| `GET /cart(.json)` | this session's cart: items, `item_count`, `total_cents` |
| `POST /cart/items` (`sku`, `quantity`) | add; refused beyond stock (422) |
| `PATCH/DELETE /cart/items/:sku` | set a quantity (0 removes), or remove |
| `POST /checkout` (`idempotency_key`) | place the order: takes stock, empties the cart; the same key returns the same order (200, not 201) |
| `GET /api/build` | dev only: sha, branch, slot and port for the footer; 204 elsewhere |

Money is integer cents everywhere, so totals can be checked exactly.

## Telemetry

The trace and report profiles of `jwalsh/context-surfaces` `slot.org` 0.1.1, attribute prefix `app`, on in every
environment. The test suite points `XDG_STATE_HOME` at a temp dir, so tests never write to the owner's state.

- Every request gets one server span and every response a `traceparent`. A valid W3C `traceparent` is continued;
  an absent or malformed one starts a new trace.
- The runner comes from `baggage` and from `?ff=driver:…,run:…,agent:…,agent-id:…` on the request. Baggage wins
  key by key. The keys are `app.driver` (`human agent webmcp playwright bombadil automation curl ops unknown`;
  any other value is `unknown`), `app.run`, `gen_ai.agent.name` and `gen_ai.agent.id`. Values must match
  `[a-z0-9-]{1,48}`; anything else is dropped.
- Each SQL statement in a request is a client child span: `db.query.summary` like `SELECT pets`, never SQL text
  or values. It is sent with `/*traceparent='00-<trace>-<its span>-01'*/`. The development log shows the statements
  as sent, tagged `[trace=<id>]`.
- Spans go to `$XDG_STATE_HOME/agentic-rails/traces.jsonl` (default `~/.local/state/agentic-rails`), one JSON line
  each, with OTLP field names.
- The page's own requests (the footer, Turbo visits and forms, WebMCP tools) send `traceparent` and the runner
  named by `?ff=` or `window.appRunner` (`app/javascript/telemetry.js`). Tool calls send `app.driver=webmcp`.
- An order records `driver` and `trace_id` when it's placed, and the checkout span carries `app.order.id`. To find
  who placed order N, read the `orders` row or the span.

```sh
bin/report --since <epoch ms>     # or --minutes N; --data DIR (default the data dir above)
gmake report MINUTES=30
curl -sD- -o/dev/null -H 'baggage: app.driver=curl,app.run=try-1' http://127.0.0.1:4900/pets.json | grep traceparent
jq -c 'select(.trace_id=="<id>")' ~/.local/state/agentic-rails/traces.jsonl
```

`bin/report` prints traces, spans, spans per driver and per run, and problems: `server-error`,
`span-without-driver`, `trace-with-two-drivers`, `missing-parent` and `not-json`. It exits 1 on any problem and on
a window with 0 traces.

The hub gate runs from the repo root against a running server:
`python3 ../../jwalsh/context-surfaces/gates/slot_check.py --url http://127.0.0.1:4900/ --data-dir ~/.local/state/agentic-rails --checkout $PWD --profiles dev,trace --prefix app --db-path /pets.json`.
