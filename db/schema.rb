# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_11_23_165640) do
  create_table "cart_items", force: :cascade do |t|
    t.integer "cart_id", null: false
    t.integer "pet_id", null: false
    t.integer "quantity", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id", "pet_id"], name: "index_cart_items_on_cart_id_and_pet_id", unique: true
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["pet_id"], name: "index_cart_items_on_pet_id"
    t.check_constraint "quantity > 0", name: "cart_items_quantity_positive"
  end

  create_table "carts", force: :cascade do |t|
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_carts_on_token", unique: true
  end

  create_table "orders", force: :cascade do |t|
    t.integer "cart_id", null: false
    t.integer "total_cents", null: false
    t.integer "item_count", null: false
    t.string "idempotency_key", null: false
    t.string "status", default: "placed", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id"], name: "index_orders_on_cart_id"
    t.index ["idempotency_key"], name: "index_orders_on_idempotency_key", unique: true
    t.check_constraint "total_cents > 0", name: "orders_total_positive"
  end

  create_table "pets", force: :cascade do |t|
    t.string "sku", null: false
    t.string "name", null: false
    t.string "species", null: false
    t.integer "price_cents", null: false
    t.integer "stock", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sku"], name: "index_pets_on_sku", unique: true
    t.check_constraint "price_cents > 0", name: "pets_price_positive"
    t.check_constraint "stock >= 0", name: "pets_stock_not_negative"
  end

  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "pets"
  add_foreign_key "orders", "carts"
end
