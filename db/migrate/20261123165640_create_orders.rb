class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :cart, null: false, foreign_key: true
      t.integer :total_cents, null: false
      t.integer :item_count, null: false
      t.string :idempotency_key, null: false
      t.string :status, null: false, default: "placed"
      t.timestamps
    end
    add_index :orders, :idempotency_key, unique: true
    add_check_constraint :orders, "total_cents > 0", name: "orders_total_positive"
  end
end
