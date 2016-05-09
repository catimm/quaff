Rails.application.routes.draw do
  
  devise_for :users, controllers: { invitations: "invitations", omniauth_callbacks: "authentications" }
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
  
  resources :breweries do
    resources :beers
    collection do
      get :autocomplete
    end   
  end

  namespace :admin do
    resources :users, :user_beer_ratings, :recommendations
  end
  
  namespace :admin do
    resources :breweries do
      resources :beers
    end
  end
  
  root :to => 'home#index'
  # route to user profile page
  get '/users/profile/:id' => 'users#profile', :as => 'user_profile'
  get '/users/activity/:id' => 'users#activity', :as => 'user_activity'
  get '/users/preferences/:id' => 'users#preferences', :as => 'user_preferences'
  get '/users/wishlist/:id' => 'users#wishlist', :as => 'user_wishlist'
  get '/users/supply/:id' => 'users#supply', :as => 'user_supply'
  get '/users/add_drink_descriptors/:id' => 'users#add_drink_descriptors', :as => 'add_drink_descriptors'
  get '/users/wishlist_removal/:id' => 'users#wishlist_removal', :as => 'wishlist_removal'
  post '/users/add_drink/:id' => 'users#add_drink', :as => 'add_drink'
  post '/users/profile/:id' => 'users#create_drink_descriptors', :as => 'create_drink_descriptors'
  post '/users/update_styles_preferences/:id' => 'users#style_preferences', :as => 'user_style_preference'
  post '/users/add_fav_drink' => 'users#add_fav_drink', :as => 'add_fav_drink'
  post '/users/set_search_box_id/:id' => 'users#set_search_box_id', :as => 'set_search_box_id'
  post '/users/remove_fav_drink/:id' => 'users#remove_fav_drink', :as => 'remove_fav_drink'
  
  get 'privacy' => 'home#privacy', :as => "privacy"
  get 'terms' => 'home#terms', :as => "terms"
  get '/draft_boards/:board_id/swap_drinks/:tap_id(.:format)' => 'draft_boards#choose_swap_drinks', :as => 'swap_drinks'
  get '/draft_boards/swap_drinks/:id(.:format)' => 'draft_boards#execute_swap_drinks', :as => 'execute_swap_drinks'
  get '/search-bloodhound-engine.js' => 'draft_boards#edit'
  get '/draft_boards/edit' => 'draft_boards#edit'
  get 'draft_boards/quick_draft_edit/:id(.:format)' => 'draft_boards#quick_draft_edit', :as => 'quick_draft_edit'
  get '/draft_boards/new_drink' => 'draft_boards#add_new_drink', :as => 'retailer_add_new_drink'
  post '/draft_boards/new_drink' => 'draft_boards#create_new_drink', :as => 'retailer_create_new_drink'
  get '/draft_boards/facebook_post_options' => 'draft_boards#facebook_post_options', :as => 'facebook_post_options'
  get '/draft_boards/share_on_facebook/:id(.:format)' => 'draft_boards#share_on_facebook', :as => 'share_on_facebook'
  get '/draft_boards/twitter_tweet_options' => 'draft_boards#twitter_tweet_options', :as => 'twitter_tweet_options'
  get '/draft_boards/share_on_twitter/:id(.:format)' => 'draft_boards#share_on_twitter', :as => 'share_on_twitter'
  post '/draft_boards/update_internal_board_preferences/:id' => 'draft_boards#update_internal_board_preferences', :as => 'update_internal_board_preferences'
  post '/draft_boards/update_web_board_preferences/:id' => 'draft_boards#update_web_board_preferences', :as => 'update_web_board_preferences'
  resources :draft_boards
  post '/drink_price_tiers(.:format)' => 'drink_price_tiers#create', :as => 'create_drink_price_tier'
  patch '/drink_price_tiers/:id(.:format)' => 'drink_price_tiers#update', :as => 'update_drink_price_tier'
  patch '/drink_price_tiers/:id/edit' => 'drink_price_tiers#update'
  resources :drink_price_tiers
  post '/drink_categories/create(.:format)' => 'drink_categories#create', :as => 'create_drink_category'
  post '/drink_categories/:id/update' => 'drink_categories#update', :as => 'update_drink_category'
  resources :drink_categories
  get '/draft_inventory/new_drink' => 'draft_inventory#add_new_drink'
  post '/draft_inventory/new_drink' => 'draft_inventory#create_new_drink'
  get '/draft_inventory/edit' => 'draft_inventory#edit'
  get '/draft_inventory/:id/edit(.:format)' => 'draft_inventory#edit', :as => 'edit_draft_inventory'
  post '/draft_inventory/:id' => 'draft_inventory#update', :as => 'specific_draft_inventory_update'
  post '/draft_inventory/update_price_tier_options/:id' => 'draft_inventory#update_price_tier_options'
  resources :draft_inventory
  post '/retailers/update_twitter_view/:id' => 'retailers#update_twitter_view'
  post '/retailers/update_team_roles/:id(.:format)' => 'retailers#update_team_roles'
  post '/retailers/info_request' => 'retailers#info_request'
  post '/stripe-webhooks' => 'retailers#stripe_webhooks'
  match '/retailers/choose_initial_plan/:id(.:format)' => 'retailers#choose_initial_plan', :as => 'choose_initial_plan', via: [:get, :post]
  match '/retailers/change_plans/:id(.:format)' => 'retailers#change_plans', :as => 'change_plans', via: [:get, :post]
  get '/retailers/retailer_delete_plan/:id' => 'retailers#delete_plan', :as => 'retailer_delete_plan'
  get '/retailers/trial_end(.:format)' => 'retailers#trial_end', :as => 'trial_end'
  get '/retailers/remove_team_member/:id' => 'retailers#remove_team_member', :as => 'remove_team_member'
  devise_scope :user do
    get '/retailers/invite_team_member_new/:id' => 'invitations#invite_team_member_new', :as => 'invite_team_member'
    post '/invitations/invite_team_member_new/:id' => 'invitations#invite_team_member_create'
  end
  get '/print_menus(.:format)' => 'print_menus#index', :as => 'print_menus'
  get '/print_menus/:id(.:format)' => 'print_menus#show', :as => 'print_menu'
  resources :retailers
  post 'home/create' => 'home#create', :as => 'invitation_request'
  post 'users/update' => 'users#update', :as => 'new_drink'
  post 'ratings/create' => 'ratings#create', :as => 'user_new_rating'
  post 'trackings/create' => 'trackings#create', :as => 'user_new_tracking'
  get 'locations' => 'locations#index'
  get 'locations/update/:id' => 'locations#update', :as => 'brewery_beer_update'
  get 'drinks/update/:id' => 'drinks#update', :as => 'listed_beer_update'
  get 'searches/add_drink' => 'searches#add_drink', :as => 'user_add_drink'
  get 'users/:user_id/ratings/new(.:format)/:id' => 'ratings#new', :as => 'new_user_rating_at_retailer'
  post 'beers/change_wishlist_setting/:id' => 'beers#change_wishlist_setting', :as => 'change_wishlist_setting'

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
  get 'admin/needs_work_beers(.:format)' => 'admin/beers#show', :as => 'admin_needs_work_beers'
  # to get clean location modal window 
  get 'admin/beers/clean_location/:beer_id' => 'admin/beers#clean_location_prep', :as => 'admin_clean_location_prep'
  # to get clean location form to display
  get 'admin/beers/locations/:beer_id' => 'admin/beers#clean_location', :as => 'admin_beer_locations'
  # to post clean location form
  post '/admin/beers/locations/:beer_id' => 'admin/beers#clean_location', :as => 'admin_clean_location'
  # user account updates
  post '/users/notification_preferences' => 'user#notification_preferences', :as => 'user_notification_preference'
  # let admin get form to add drink to order queue
  get 'admin/recommendations/order_queue_new/:id' => 'admin/recommendations#order_queue_new', :as => 'admin_order_queue_new'
  # let admin add drink to order queue
  post 'admin/recommendations/order_queue_create' => 'admin/recommendations#order_queue_create', :as => 'admin_order_queue_create'
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
