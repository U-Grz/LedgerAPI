# config/routes.rb
Rails.application.routes.draw do
  root "pages#home"
  
  # Authentication Routes
  get    "login",  to: "sessions#new",     as: :login
  post   "login",  to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout
  
  get  "signup", to: "registrations#new",    as: :signup
  post "signup", to: "registrations#create"
  
  # Dashboard
  get "dashboard", to: "dashboard#index", as: :dashboard
  
  # Transactions (Web Interface) - Point to Web namespace
  resources :transactions, controller: 'web/transactions'
  
  # API ROUTES
  namespace :api, defaults: { format: :json } do
    post '/signup', to: 'authentication#signup'
    post '/login',  to: 'authentication#login'
    
    resources :transactions, only: [:index, :show, :create, :update, :destroy] do
      collection do
        get :summary
        get :balance
      end
    end
  end
  
  get "up", to: "rails/health#show", as: :rails_health_check
end