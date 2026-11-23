# agentic-rails

A small Rails pet shop used as a workshop for agentic, worktree-based development, where telemetry comes first.
It ports what jwalsh/gforth-hp48 built:
- named runners, and one trace id across every log;
- a log check that fails loudly;
- dev-only tool endpoints;
- Chrome WebMCP tools;
- Playwright and Bombadil end-to-end testing.

The port plan is `.meta/context-surfaces-port.org`.

Bare metal: Homebrew Ruby 3.4.5, Rails 8, SQLite. The development database lives in
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
