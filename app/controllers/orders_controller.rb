class OrdersController < ApplicationController
  def create
    key = params[:idempotency_key].presence || request.headers["Idempotency-Key"].presence ||
          raise(ActionController::ParameterMissing, :idempotency_key)
    trace = Telemetry.current
    order, created = Order.place!(current_cart, key, driver: trace&.driver, trace_id: trace&.trace_id)
    trace&.set_attribute("app.order.id", order.id)
    respond_to do |format|
      format.html { redirect_to order_path(order), notice: created ? "Order placed" : "Already placed" }
      format.json { render json: order_json(order).merge(created: created), status: created ? :created : :ok }
    end
  end

  def show
    @order = current_cart.orders.find(params[:id])
    respond_to do |format|
      format.html
      format.json { render json: order_json(@order) }
    end
  end

  private

  def order_json(order) = order.slice(:id, :total_cents, :item_count, :idempotency_key, :status, :driver, :trace_id)
end
