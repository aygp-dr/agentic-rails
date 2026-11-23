class CreatePets < ActiveRecord::Migration[8.0]
  def change
    create_table :pets do |t|
      t.string :sku, null: false
      t.string :name, null: false
      t.string :species, null: false
      t.integer :price_cents, null: false
      t.integer :stock, null: false, default: 0
      t.timestamps
    end
    add_index :pets, :sku, unique: true
    add_check_constraint :pets, "price_cents > 0", name: "pets_price_positive"
    add_check_constraint :pets, "stock >= 0", name: "pets_stock_not_negative"
  end
end
