# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your migrations
# from scratch. Old migrations may fail to apply correctly if those migrations use
# external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2024_01_01_000003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "products", force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, null: false
    t.integer "inventory_count", default: 0, null: false
    t.boolean "featured", default: false
    t.string "sku", limit: 50
    t.string "status", default: "active"
    t.float "risk_score", default: 0.0
    t.string "risk_status", default: "pending"
    t.datetime "risk_assessed_at"
    t.jsonb "risk_factors", default: {}
    t.jsonb "risk_mitigations", default: {}
    t.integer "view_count", default: 0
    t.integer "purchase_count", default: 0
    t.float "conversion_rate", default: 0.0
    t.jsonb "performance_metrics", default: {}
    t.jsonb "metadata", default: {}
    t.string "tags", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_products_on_created_at"
    t.index ["featured"], name: "index_products_on_featured"
    t.index ["metadata"], name: "index_products_on_metadata", using: :gin
    t.index ["name"], name: "index_products_on_name"
    t.index ["risk_score"], name: "index_products_on_risk_score"
    t.index ["sku"], name: "index_products_on_sku", unique: true
    t.index ["status"], name: "index_products_on_status"
    t.index ["tags"], name: "index_products_on_tags", using: :gin
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.string "status", default: "active"
    t.datetime "last_login_at"
    t.integer "login_count", default: 0
    t.float "risk_score", default: 0.0
    t.string "risk_level", default: "low"
    t.datetime "risk_assessed_at"
    t.jsonb "risk_factors", default: {}
    t.integer "failed_login_attempts", default: 0
    t.datetime "locked_at"
    t.integer "orders_count", default: 0
    t.decimal "total_spent", precision: 12, scale: 2, default: "0.0"
    t.float "churn_probability", default: 0.0
    t.datetime "last_activity_at"
    t.float "avg_session_duration", default: 0.0
    t.integer "page_views_count", default: 0
    t.jsonb "behavior_metrics", default: {}
    t.jsonb "preferences", default: {}
    t.string "timezone", default: "UTC"
    t.string "locale", default: "en"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_users_on_created_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["last_login_at"], name: "index_users_on_last_login_at"
    t.index ["preferences"], name: "index_users_on_preferences", using: :gin
    t.index ["risk_level"], name: "index_users_on_risk_level"
    t.index ["risk_score"], name: "index_users_on_risk_score"
    t.index ["status"], name: "index_users_on_status"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "order_number", null: false
    t.string "status", default: "pending"
    t.decimal "total_amount", precision: 12, scale: 2, null: false
    t.decimal "tax_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "shipping_amount", precision: 10, scale: 2, default: "0.0"
    t.string "payment_status", default: "pending"
    t.datetime "paid_at"
    t.datetime "shipped_at"
    t.datetime "delivered_at"
    t.datetime "cancelled_at"
    t.float "risk_score", default: 0.0
    t.string "risk_level", default: "low"
    t.jsonb "risk_factors", default: {}
    t.boolean "fraud_check_required", default: false
    t.string "fraud_check_status"
    t.jsonb "fraud_check_results", default: {}
    t.float "processing_time"
    t.integer "fulfillment_attempts", default: 0
    t.jsonb "performance_metrics", default: {}
    t.jsonb "shipping_address", default: {}
    t.jsonb "billing_address", default: {}
    t.string "shipping_method"
    t.string "tracking_number"
    t.text "notes"
    t.jsonb "metadata", default: {}
    t.string "source", default: "web"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_orders_on_created_at"
    t.index ["metadata"], name: "index_orders_on_metadata", using: :gin
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
    t.index ["payment_status"], name: "index_orders_on_payment_status"
    t.index ["risk_score"], name: "index_orders_on_risk_score"
    t.index ["shipped_at"], name: "index_orders_on_shipped_at"
    t.index ["status"], name: "index_orders_on_status"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  add_foreign_key "orders", "users"
end