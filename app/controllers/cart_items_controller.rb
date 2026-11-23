class CartItemsController < ApplicationController
  def create
    pet = Pet.find_by!(sku: params.require(:sku))
    current_cart.add(pet, quantity_param(default: 1))
    done "Added #{pet.name}"
  end

  def update
    pet = Pet.find_by!(sku: params[:pet_id])
    current_cart.set_quantity(pet, quantity_param(default: 0))
    done "Updated #{pet.name}"
  end

  def destroy
    pet = Pet.find_by!(sku: params[:pet_id])
    current_cart.remove(pet)
    done "Removed #{pet.name}"
  end

  private

  def quantity_param(default:) = Integer(params.fetch(:quantity, default))

  def done(notice)
    respond_to do |format|
      format.html { redirect_to cart_path, notice: notice }
      format.json { render json: current_cart.reload.as_summary }
    end
  end
end
