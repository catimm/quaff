Rails.application.routes.draw do
  
  devise_for :users
  resources :users do
    resources :drinks, :ratings, :rewards   
  end
  resources :beers do
    collection do
      get :descriptors, as: :descriptors
    end
  end 
  resources :locations
  resources :breweries do
    resources :beers   
  end
  
  scope "/admin" do
    resources :users, :breweries
  end
  
  root :to => 'home#index'
  get 'home/update' => 'home#update', :as => 'show_beers'
  post 'users/update' => 'users#update', :as => 'new_drink'
  post 'drinks/update' => 'drinks#update', :as => 'user_beer_ratings'
  get 'locations' => 'locations#index'
  get 'locations/update/:id' => 'locations#update', :as => 'brewery_beer_update'
  get 'reloads' => 'reloads#index'
  get 'beers/current_beers' => 'beers#current_beers', :as => 'current_beers', :path => "/currentbeers"
  put 'breweries/update' => 'breweries#update'
  get 'breweries/alt_names/:id' => 'breweries#alt_brewery_name', :as => 'alt_brewery_names'
  post 'breweries/alt_names' => 'breweries#create_alt_brewery', :as => 'create_brewery_names'
  get 'beers/alt_names/:id' => 'beers#alt_beer_name', :as => 'alt_beer_names'
  post 'beers/alt_names' => 'beers#create_alt_beer', :as => 'create_beer_names'
  get 'beers/delete_beer/:brewery_id/:id' => 'beers#delete_beer_prep', :as => 'delete_beer_prep'
  
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

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
