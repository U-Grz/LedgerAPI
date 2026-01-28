Rails.application.routes.draw do

  # POST /signup - Create new user account
  post '/signup', to: 'authentication#signup'
  
  # POST /login - Login and get JWT token
  post '/login', to: 'authentication#login'

  resources :transactions do
    collection do
      get :summary
      get :balance
    end
  end
end

