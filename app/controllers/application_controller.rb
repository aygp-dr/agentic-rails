class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  rescue_from Cart::OutOfStock, Order::EmptyCart do |error|
    respond_to do |format|
      format.html { redirect_back fallback_location: cart_path, alert: error.message }
      format.json { render json: { error: error.message }, status: :unprocessable_entity }
    end
  end

  private

  # One cart per browser session, created lazily.
  def current_cart
    @current_cart ||= begin
      token = session[:cart_token] ||= SecureRandom.hex(16)
      Cart.find_or_create_by!(token: token)
    end
  end
  helper_method :current_cart
end
