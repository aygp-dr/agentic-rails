Rails.application.routes.draw do
  root "pets#index"

  resources :pets, only: [:index, :show]
  resource :cart, only: [:show] do
    post   "items",         to: "cart_items#create",  as: :items
    patch  "items/:pet_id", to: "cart_items#update",  as: :item
    delete "items/:pet_id", to: "cart_items#destroy"
  end
  post "checkout", to: "orders#create", as: :checkout
  resources :orders, only: [:show]

  # Dev-only tool endpoints (404 in other environments; see ApplicationController)
  namespace :api do
    get "build", to: "dev#build"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
