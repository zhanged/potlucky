Potlucky::Application.routes.draw do
  get "twilio/respond"
  resources :users #, except: [:new]
  resources :sessions, only: [:new, :create, :destroy]
  resources :gathers,  only: [:show, :index, :create, :update, :destroy]
  resources :calinvites,  only: [:create, :update, :destroy]
  resources :invitations, only: [:create, :update, :destroy]
  resources :password_resets, only: [:new, :create]
  resources :wait_lists, only: [:new, :create]
  resources :tnumbers, only: [:new, :create, :destroy]
  resources :friendships, only: [:new, :create, :destroy]
  resources :updates, only: [:create, :destroy]
  resources :invite_mores, only: [:create, :destroy]
  resources :links
  resources :lists , only: [:create, :destroy]
  root to: 'static_pages#home'
  match '/signup',  to: 'users#new',           via: 'get'
  match '/lets_go',    to: 'users#lets_go',        via: 'get'
  match '/welcome',    to: 'static_pages#welcome',        via: 'get'
  match '/email_redirect', to: 'users#email_redirect',  via: 'get'
  match '/reset', to: 'password_resets#new',  via: 'get'  
  match '/signin',  to: 'sessions#new',        via: 'get'
  match '/signout', to: 'sessions#destroy',    via: 'delete'
  match '/help',    to: 'static_pages#help',   via: 'get'
  match '/about',   to: 'static_pages#about',  via: 'get'
  match '/faq',   to: 'static_pages#faq',  via: 'get'
  match '/more',   to: 'static_pages#more',  via: 'get'
  match '/how',   to: 'static_pages#how',  via: 'get'
  # match '/new',  to: 'gathers#new',           via: 'get'
  match ':in_url', to: 'links#go',           via: 'get'
  match '/:id', to: 'gathers#show', via: 'get'
  match 'auth/:provider/callback', to: 'sessions#create', via: [:get, :post]
  match 'auth/failure', to: redirect('/'), via: [:get, :post]


  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
