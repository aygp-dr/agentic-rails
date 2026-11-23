// WebMCP: the shop registers its own tools for browser agents and DevTools
// (Application > WebMCP lists them and every call). Chrome's imperative API,
// document.modelContext.registerTool, is behind a flag or origin trial, so it
// is feature-detected: without it the page is unchanged.
// https://developer.chrome.com/docs/ai/webmcp/imperative-api
//
// Each tool calls the same JSON endpoints the forms post to, in this page's
// session (same cookie, same cart), and names itself app.driver=webmcp in
// W3C baggage, with its own traceparent, so a tool call's server span (and
// an order it places) can be told apart from a click. The page's run and
// agent, if ?ff= named them, ride along. Annotations: read-only tools say so; checkout is the one
// consequential action; anything echoing pet or cart text is untrusted content.

import { traceHeaders } from "telemetry"

const context = () => document.modelContext ?? navigator.modelContext

const csrf = () => document.querySelector('meta[name="csrf-token"]')?.content

async function call(method, path, body) {
  const headers = { Accept: "application/json", ...traceHeaders({ driver: "webmcp" }) }
  if (body) headers["Content-Type"] = "application/json"
  if (method !== "GET") headers["X-CSRF-Token"] = csrf()
  const response = await fetch(path, {
    method, headers, credentials: "same-origin", body: body && JSON.stringify(body)
  })
  const payload = await response.json().catch(() => ({}))
  const traceparent = response.headers.get("traceparent")
  const result = Array.isArray(payload) ? { status: response.status, items: payload }
                                       : { status: response.status, ...payload }
  if (traceparent) result.trace_id = traceparent.split("-")[1]
  if (!response.ok && !payload.error) result.error = `HTTP ${response.status}`
  return result
}

// Keep the page in step with what a tool did: the header's count, and the
// cart page itself if that is what is showing.
function refresh(cart) {
  const count = document.getElementById("cart-count")
  if (count && typeof cart?.item_count === "number") count.textContent = cart.item_count
  if (location.pathname === "/cart" && window.Turbo) window.Turbo.visit("/cart", { action: "replace" })
}

const sku = { type: "string", description: "The pet's sku, from shop_search_products or shop_read_cart, e.g. DOG-001." }

const tools = [
  {
    name: "shop_search_products",
    description: "Searches the pet shop's catalogue. Returns matching pets with sku, name, species, price_cents (US cents: 18000 is $180.00) and stock. All filters are optional; with none, returns every pet. Use before adding to the cart: the sku is what the cart tools take.",
    inputSchema: {
      type: "object",
      properties: {
        query: { type: "string", description: "Words to match in the name or species, case-insensitive." },
        species: { type: "string", description: "Exact species, e.g. dog, cat, fish." },
        in_stock: { type: "boolean", description: "true for pets with stock > 0 only." },
        max_price_cents: { type: "integer", minimum: 0, description: "Highest price to include, in US cents (e.g. 5000 for $50.00)." }
      }
    },
    annotations: { readOnlyHint: true, untrustedContentHint: true },
    async execute({ query, species, in_stock, max_price_cents } = {}) {
      const result = await call("GET", "/pets.json")
      if (result.error) return result
      const pets = result.items
      const words = (query ?? "").toLowerCase().split(/\s+/).filter(Boolean)
      const matches = pets.filter((pet) =>
        words.every((w) => `${pet.name} ${pet.species}`.toLowerCase().includes(w)) &&
        (!species || pet.species === species.toLowerCase()) &&
        (!in_stock || pet.stock > 0) &&
        (max_price_cents == null || pet.price_cents <= max_price_cents))
      return { pets: matches, count: matches.length, trace_id: result.trace_id }
    }
  },
  {
    name: "shop_add_to_cart",
    description: "Adds a pet to this page's cart by sku (default quantity 1) and returns the cart. Refused with an error if the stock would run out. Undoable with shop_update_cart.",
    inputSchema: {
      type: "object",
      properties: { sku,
                    quantity: { type: "integer", minimum: 1, maximum: 99,
                                description: "How many to add, 1 to 99; default 1. Added to any already in the cart." } },
      required: ["sku"]
    },
    annotations: { readOnlyHint: false, consequentialHint: false, untrustedContentHint: true },
    async execute({ sku, quantity = 1 }) {
      const cart = await call("POST", "/cart/items", { sku, quantity })
      refresh(cart)
      return cart
    }
  },
  {
    name: "shop_update_cart",
    description: "Sets the quantity of a pet already in the cart; 0 removes it. Returns the cart.",
    inputSchema: {
      type: "object",
      properties: { sku,
                    quantity: { type: "integer", minimum: 0, maximum: 99,
                                description: "The new quantity for that line, 0 to 99; 0 removes the pet from the cart." } },
      required: ["sku", "quantity"]
    },
    annotations: { readOnlyHint: false, consequentialHint: false, untrustedContentHint: true },
    async execute({ sku, quantity }) {
      const cart = await call("PATCH", `/cart/items/${encodeURIComponent(sku)}`, { quantity })
      refresh(cart)
      return cart
    }
  },
  {
    name: "shop_read_cart",
    description: "Returns this page's cart: items (sku, name, quantity, price_cents, line_cents), item_count and total_cents, all amounts in US cents. Changes nothing.",
    inputSchema: { type: "object", properties: {} },
    annotations: { readOnlyHint: true, untrustedContentHint: true },
    async execute() {
      return call("GET", "/cart")
    }
  },
  {
    name: "shop_checkout",
    description: "Places an order for everything in the cart, takes the stock and empties the cart. This cannot be undone. Pass the same idempotency_key to retry safely: a repeat returns the existing order with created false. Confirm with the user before calling.",
    inputSchema: {
      type: "object",
      properties: { idempotency_key: { type: "string", description: "Any unique string; generated if omitted." } }
    },
    annotations: { readOnlyHint: false, consequentialHint: true },
    async execute({ idempotency_key } = {}) {
      const key = idempotency_key || crypto.randomUUID()
      const order = await call("POST", "/checkout", { idempotency_key: key })
      if (order.status < 300) refresh({ item_count: 0 })
      return { ...order, idempotency_key: order.idempotency_key ?? key }
    }
  }
]

let controller

export function register() {
  const modelContext = context()
  if (!modelContext || controller) return
  controller = new AbortController()
  for (const tool of tools) {
    Promise.resolve(modelContext.registerTool(tool, { signal: controller.signal }))
      .catch((error) => console.warn(`registerTool ${tool.name}:`, error))
  }
}

register()
