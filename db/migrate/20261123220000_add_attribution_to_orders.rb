# Who placed an order: the runner's driver and the trace of the checkout
# request, recorded at placement. Nullable: orders placed outside a request
# (seeds, the console) and orders from before this migration have neither.
class AddAttributionToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :driver, :string
    add_column :orders, :trace_id, :string
    add_index :orders, :trace_id
  end
end
