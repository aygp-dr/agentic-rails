# The example catalogue. Fixed and deterministic, so Playwright, Bombadil and
# the report oracles always start from the same data. Idempotent: running it
# again resets each pet's price and stock to these values.
#
# Stock is chosen to exercise boundaries: a pet with stock 1 (sells out on one
# checkout), one with stock 0 (never addable), and plenty of the rest.
CATALOGUE = [
  # sku,       name,               species,  price_cents, stock
  ["DOG-001", "Biscuit",          "dog",     45_000,      3],
  ["DOG-002", "Pepper",           "dog",     52_500,      1],
  ["CAT-001", "Miso",             "cat",     30_000,      5],
  ["CAT-002", "Juniper",          "cat",     27_500,      0],
  ["BRD-001", "Kiwi",             "bird",     8_999,     12],
  ["BRD-002", "Sunny",            "bird",    12_050,      4],
  ["FSH-001", "Bubbles",          "fish",       499,     50],
  ["FSH-002", "Captain Fin",      "fish",     1_250,     20],
  ["RPT-001", "Basil",            "reptile", 18_000,      2],
  ["RBT-001", "Clover",           "rabbit",  15_000,      6]
].freeze

CATALOGUE.each do |sku, name, species, price_cents, stock|
  pet = Pet.find_or_initialize_by(sku: sku)
  pet.update!(name: name, species: species, price_cents: price_cents, stock: stock)
end

puts "seeded #{Pet.count} pets (#{Pet.sum(:stock)} in stock)"
