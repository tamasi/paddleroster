Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :invitations, param: :token, only: %i[ create show update ]

  get "calendario", to: "turnos#index", as: :calendario
  resources :turnos, only: %i[ new create show update ] do
    member do
      patch :cancel
    end
    resources :payments, only: [ :create ]
  end
  get "pagos", to: "payments#index", as: :pagos
  get "reportes", to: "reports#index", as: :reportes

  resource :configuracion, controller: :configuracion, only: %i[ show edit update ] do
    resources :canchas
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "inicio#index"
end
