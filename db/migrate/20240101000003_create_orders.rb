class CreateOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :order_number, null: false
      t.string :status, default: 'pending'
      t.decimal :total_amount, precision: 12, scale: 2, null: false
      t.decimal :tax_amount, precision: 10, scale: 2, default: 0.0
      t.decimal :shipping_amount, precision: 10, scale: 2, default: 0.0
      t.string :payment_status, default: 'pending'
      t.datetime :paid_at
      t.datetime :shipped_at
      t.datetime :delivered_at
      t.datetime :cancelled_at

      # Risk assessment
      t.float :risk_score, default: 0.0
      t.string :risk_level, default: 'low'
      t.jsonb :risk_factors, default: {}
      t.boolean :fraud_check_required, default: false
      t.string :fraud_check_status
      t.jsonb :fraud_check_results, default: {}

      # Performance tracking
      t.float :processing_time # seconds
      t.integer :fulfillment_attempts, default: 0
      t.jsonb :performance_metrics, default: {}

      # Shipping information
      t.jsonb :shipping_address, default: {}
      t.jsonb :billing_address, default: {}
      t.string :shipping_method
      t.string :tracking_number

      # Additional data
      t.text :notes
      t.jsonb :metadata, default: {}
      t.string :source, default: 'web'
      t.string :ip_address

      t.timestamps
    end

    add_index :orders, :user_id
    add_index :orders, :order_number, unique: true
    add_index :orders, :status
    add_index :orders, :payment_status
    add_index :orders, :risk_score
    add_index :orders, :created_at
    add_index :orders, :shipped_at
    add_index :orders, :metadata, using: 'gin'
  end
end