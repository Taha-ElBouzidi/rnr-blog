Rails.application.routes.draw do
  devise_for :users
  get "menu" => "menu#index", as: :menu
  
  # Account management
  resource :account, only: [:edit, :update]
  
  # Admin panel
  namespace :admin do
    root to: "dashboard#index"
    resources :users, only: [:index, :update, :destroy]
    resources :posts, only: [:index, :destroy]
    resources :comments, only: [:index, :destroy] do
      collection do
        delete :bulk_destroy
      end
    end
  end
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  root "posts#index"
  resources :posts do
    member do
      patch :publish
      patch :unpublish
    end
    resources :comments, only: [:create, :destroy]
  end


end
