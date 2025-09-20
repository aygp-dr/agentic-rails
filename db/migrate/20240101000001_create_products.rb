class CreateProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :products do |t|
      t.string :name, null: false, limit: 255
      t.text :description
      t.decimal :price, precision: 10, scale: 2, null: false
      t.integer :inventory_count, default: 0, null: false
      t.boolean :featured, default: false
      t.string :sku, limit: 50
      t.string :status, default: 'active'

      # Risk-aware columns
      t.float :risk_score, default: 0.0
      t.string :risk_status, default: 'pending'
      t.datetime :risk_assessed_at
      t.jsonb :risk_factors, default: {}
      t.jsonb :risk_mitigations, default: {}

      # Performance tracking columns
      t.integer :view_count, default: 0
      t.integer :purchase_count, default: 0
      t.float :conversion_rate, default: 0.0
      t.jsonb :performance_metrics, default: {}

      # Metadata
      t.jsonb :metadata, default: {}
      t.string :tags, array: true, default: []

      t.timestamps
    end

    add_index :products, :name
    add_index :products, :sku, unique: true
    add_index :products, :status
    add_index :products, :featured
    add_index :products, :risk_score
    add_index :products, :tags, using: 'gin'
    add_index :products, :metadata, using: 'gin'
    add_index :products, :created_at
  end
end