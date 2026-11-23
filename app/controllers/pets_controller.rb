class PetsController < ApplicationController
  def index
    @pets = Pet.catalogue
    respond_to do |format|
      format.html
      format.json { render json: @pets.map { pet_json(_1) } }
    end
  end

  def show
    @pet = Pet.find_by!(sku: params[:id])
    respond_to do |format|
      format.html
      format.json { render json: pet_json(@pet) }
    end
  end

  private

  def pet_json(pet) = pet.slice(:sku, :name, :species, :price_cents, :stock)
end
