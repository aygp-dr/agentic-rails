Rails.application.routes.draw do
  root "pets#index"

  resources :pets, only: [:index, :show]
  resource :cart, only: [:show]
  # Named here, not inside the resource block: there they'd be items_cart_path.
  post   "cart/items",         to: "cart_items#create",  as: :cart_items
  patch  "cart/items/:pet_id", to: "cart_items#update",  as: :cart_item
  delete "cart/items/:pet_id", to: "cart_items#destroy"
  post "checkout", to: "orders#create", as: :checkout
  resources :orders, only: [:show]

  # Dev-only tool endpoints (404 in other environments; see ApplicationController)
  namespace :api do
    get "build", to: "dev#build"
  end
  get ".well-known/appspecific/com.chrome.devtools.json", to: "api/dev#workspace", format: false

  get "up" => "rails/health#show", as: :rails_health_check
end
