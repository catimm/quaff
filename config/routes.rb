Rails.application.routes.draw do
  
  devise_for :users, controllers: { invitations: "invitations" }
  resources :users do
    resources :drinks, :ratings, :rewards, :trackings   
  end

  resource :user, only: [:edit] do
    collection do
      patch 'update_password'
    end
  end
  
  # for Knird admins to add/edit breweries and drinks
  namespace :admin do
    resources :beers do
      collection do
        get :descriptors, as: :descriptors
      end
    end 
 end
 
 # for retailers to add draft board iframe widget
 namespace :draft do
   resources :drinks, only: :show, path: "" # -> drinkknird.com/draft/1
 end
 
 resources :beers do
   collection do
     get :descriptors, as: :descriptors
   end
 end 
  
  resources :locations
  resources :retailers
  
  resources :breweries do
    resources :beers
    collection do
      get :autocomplete
    end   
  end

  namespace :admin do
    resources :users, :user_beer_ratings
  end
  
  namespace :admin do
    resources :breweries do
      resources :beers
    end
  end
  
  root :to => 'home#index'
  get 'privacy' => 'home#privacy', :as => "privacy"
  get 'terms' => 'home#terms', :as => "terms"
  get '/search-bloodhound-engine.js' => 'draft_boards#edit'
  get '/draft_boards/edit' => 'draft_boards#edit'
  get 'draft_boards/new_drink' => 'draft_boards#add_new_drink', :as => 'retailer_add_new_drink'
  post 'draft_boards/new_drink' => 'draft_boards#create_new_drink', :as => 'retailer_create_new_drink'
  resources :draft_boards
  get '/draft_inventory/new(.:format)' => 'draft_inventory#new', :as => 'new_draft_inventory'
  get '/draft_inventory/:id/edit(.:format)' => 'draft_inventory#edit', :as => 'edit_draft_inventory'
  get '/draft_inventory/edit' => 'draft_inventory#edit'
  patch '/draft_inventory/:id(.:format)' => 'draft_inventory#update'
  post 'home/create' => 'home#create', :as => 'invitation_request'
  post 'users/update' => 'users#update', :as => 'new_drink'
  post 'ratings/create' => 'ratings#create', :as => 'user_new_rating'
  post 'trackings/create' => 'trackings#create', :as => 'user_new_tracking'
  get 'locations' => 'locations#index'
  get 'locations/update/:id' => 'locations#update', :as => 'brewery_beer_update'
  get 'drinks/update/:id' => 'drinks#update', :as => 'listed_beer_update'
  get 'searches/add_beer' => 'searches#add_beer', :as => 'user_add_beer'
  get 'users/:user_id/ratings/new(.:format)/:retailer_id' => 'ratings#new', :as => 'new_user_rating_at_retailer'

  # admin routes
  get 'porting' => 'porting#index'
  get 'reloads' => 'reloads#index'
  get 'admin/beers/current_beers' => 'admin/beers#current_beers', :as => 'admin_current_beers', :path => "/currentbeers"
  put 'admin/breweries/update' => 'admin/breweries#update'
  get 'admin/breweries/alt_names/:id' => 'admin/breweries#alt_brewery_name', :as => 'admin_alt_brewery_names'
  post 'admin/breweries/alt_names' => 'admin/breweries#create_alt_brewery', :as => 'admin_create_brewery_names'
  get 'admin/beers/alt_names/:id' => 'admin/beers#alt_beer_name', :as => 'admin_alt_beer_names'
  post 'admin/beers/alt_names' => 'admin/beers#create_alt_beer', :as => 'admin_create_beer_names'
  get 'admin/beers/delete_beer/:brewery_id/:id' => 'admin/beers#delete_beer_prep', :as => 'admin_delete_beer_prep'
  # to get clean location modal window 
  get 'admin/beers/clean_location/:beer_id' => 'admin/beers#clean_location_prep', :as => 'admin_clean_location_prep'
  # to get clean location form to display
  get 'admin/beers/locations/:beer_id' => 'admin/beers#clean_location', :as => 'admin_beer_locations'
  # to post clean location form
  post '/admin/beers/locations/:beer_id' => 'admin/beers#clean_location', :as => 'admin_clean_location'
  # user account updates
  post '/users/notification_preferences' => 'user#notification_preferences', :as => 'user_notification_preference'
  # user beer preferences
  post '/styles' => 'users#style_preferences', :as => 'user_style_preference'
  
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
