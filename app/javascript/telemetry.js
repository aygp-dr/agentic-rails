// Runner identity and trace headers for the page's own requests (slot.org
// T1, T3, T5). A page can't set headers on its own navigation, so the server
// reads ?ff= on that request; every request the page makes after that (the
// dev footer, Turbo visits and form submissions, WebMCP tool calls) sends a
// W3C traceparent, a fresh trace per request, and baggage naming the runner.
//
// The runner comes from ?ff=driver:<d>,run:<r>,agent:<a>,agent-id:<i> on the
// URL the page was loaded with, or from window.appRunner = {driver, run,
// agent, agentId} set by an init script (Playwright). It is captured once:
// Turbo keeps this module across visits, so a run named on the landing URL
// names the rest of the tab's requests. Nothing is stored. Nothing here
// promotes a page to human (T4 MAY): unnamed traffic stays unknown.

const KEYS = { driver: "app.driver", run: "app.run", agent: "gen_ai.agent.name", "agent-id": "gen_ai.agent.id" }
const VALUE = /^[a-z0-9-]{1,48}$/

function fromFF(search) {
  const runner = {}
  for (const item of (new URLSearchParams(search).get("ff") ?? "").split(",")) {
    const colon = item.indexOf(":")
    const name = item.slice(0, colon).trim()
    if (colon > 0 && name in KEYS) runner[name] = item.slice(colon + 1).trim()
  }
  return runner
}

function fromWindow() {
  const set = window.appRunner
  if (!set) return {}
  const runner = { driver: set["driver"], run: set["run"], agent: set["agent"], "agent-id": set["agentId"] }
  return Object.fromEntries(Object.entries(runner).filter(([, value]) => value != null))
}

const runner = { ...fromFF(location.search), ...fromWindow() }

const hex = (bytes) =>
  Array.from(crypto.getRandomValues(new Uint8Array(bytes)), (b) => b.toString(16).padStart(2, "0")).join("")

// {traceparent, baggage?} for one request; overrides replace runner fields
// (webmcp.js passes {driver: "webmcp"}). Invalid values are left out, as the
// server would drop them anyway.
export function traceHeaders(overrides = {}) {
  const named = { ...runner, ...fromFF(location.search), ...overrides }
  const baggage = Object.entries(KEYS)
    .filter(([name]) => VALUE.test(named[name] ?? ""))
    .map(([name, key]) => `${key}=${named[name]}`)
    .join(",")
  const headers = { traceparent: `00-${hex(16)}-${hex(8)}-01` }
  if (baggage) headers["baggage"] = baggage
  return headers
}

// Turbo Drive visits, prefetches and form submissions are fetches too.
document.addEventListener("turbo:before-fetch-request", (event) => {
  Object.assign(event.detail.fetchOptions.headers, traceHeaders())
})
