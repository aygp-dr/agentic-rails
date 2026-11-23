class CreateCartItems < ActiveRecord::Migration[8.0]
  def change
    create_table :cart_items do |t|
      t.references :cart, null: false, foreign_key: true
      t.references :pet, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.timestamps
    end
    add_index :cart_items, [:cart_id, :pet_id], unique: true
    add_check_constraint :cart_items, "quantity > 0", name: "cart_items_quantity_positive"
  end
end
