class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :first_name
      t.string :last_name
      t.string :phone
      t.string :status, default: 'active'
      t.datetime :last_login_at
      t.integer :login_count, default: 0

      # Risk assessment columns
      t.float :risk_score, default: 0.0
      t.string :risk_level, default: 'low'
      t.datetime :risk_assessed_at
      t.jsonb :risk_factors, default: {}
      t.integer :failed_login_attempts, default: 0
      t.datetime :locked_at

      # Activity tracking
      t.integer :orders_count, default: 0
      t.decimal :total_spent, precision: 12, scale: 2, default: 0.0
      t.float :churn_probability, default: 0.0
      t.datetime :last_activity_at

      # Performance metrics
      t.float :avg_session_duration, default: 0.0
      t.integer :page_views_count, default: 0
      t.jsonb :behavior_metrics, default: {}

      # Preferences and settings
      t.jsonb :preferences, default: {}
      t.string :timezone, default: 'UTC'
      t.string :locale, default: 'en'

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :status
    add_index :users, :risk_score
    add_index :users, :risk_level
    add_index :users, :last_login_at
    add_index :users, :created_at
    add_index :users, :preferences, using: 'gin'
  end
end