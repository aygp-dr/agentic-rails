Rails.application.routes.draw do
  # Health check endpoint for monitoring
  get '/health', to: 'health#check'

  # API namespace with versioning
  namespace :api do
    namespace :v1 do
      resources :products do
        member do
          post :update_inventory
          get :risk_assessment
        end
        collection do
          get :high_risk
          get :performance_metrics
        end
      end

      resources :orders do
        member do
          post :cancel
          post :fulfill
          get :risk_report
        end
      end

      resources :users do
        member do
          get :activity_metrics
          get :risk_profile
        end
      end

      # Monitoring endpoints
      namespace :monitoring do
        get :metrics
        get :alerts
        get :performance
        get :risks
      end

      # Scaling controls
      namespace :scaling do
        post :trigger
        get :status
        get :history
      end
    end
  end

  # Admin interface
  namespace :admin do
    resources :risk_assessments, only: [:index, :show]
    resources :performance_reports, only: [:index, :show]
    resources :deployments, only: [:index, :show, :create]

    # Feature flags management
    resources :feature_flags do
      member do
        post :enable
        post :disable
      end
    end
  end

  # ActionCable routes
  mount ActionCable.server => '/cable'

  # Progressive Web App manifest
  get '/manifest.json', to: 'pwa#manifest'
  get '/service-worker.js', to: 'pwa#service_worker'

  # Root route
  root 'dashboard#index'

  # Catch-all for unmatched routes (useful for SPA)
  get '*path', to: 'application#not_found', constraints: lambda { |req|
    !req.xhr? && req.format.html?
  }
end