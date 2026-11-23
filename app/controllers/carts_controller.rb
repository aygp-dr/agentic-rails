class CartsController < ApplicationController
  def show
    respond_to do |format|
      format.html
      format.json { render json: current_cart.as_summary }
    end
  end
end
