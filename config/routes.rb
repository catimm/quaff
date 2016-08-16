Rails.application.routes.draw do
  
  devise_for :users, controllers: { invitations: "invitations", omniauth_callbacks: "authentications" }
  resources :users do
    resources :drinks, :ratings, :rewards, :trackings   
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
    resources :users, :user_beer_ratings, :recommendations, :inventories, :fulfillment
  end
  
  namespace :admin do
    resources :breweries do
      resources :beers
    end
  end
  
  root :to => 'home#index'
  # routes to user profile pages
  get '/users/account_settings/:id' => 'users#account_settings', :as => 'user_account_settings'  
  get '/users/plan_rewewal_update/:id' => 'users#plan_rewewal_update', :as => 'plan_rewewal_update' 
  post '/users/update_profile/:id' => 'users#update_profile'
  post '/users/update_delivery_address/:id' => 'users#update_delivery_address'
  patch '/users/update_password/:id' => 'users#update_password'
  post '/users/choose_plan/:id' => 'users#choose_plan', :as => 'choose_plan'
  post '/stripe-webhooks' => 'users#stripe_webhooks'
  
  # routes to user deliveries pages
  get '/deliveries/deliveries/:id' => 'deliveries#deliveries', :as => 'user_deliveries'
  get '/deliveries/delivery_settings/:id' => 'deliveries#delivery_settings', :as => 'user_delivery_settings'
  post '/deliveries/deliveries_update_estimates/:id' => 'deliveries#deliveries_update_estimates', :as => 'deliveries_update_estimates'
  patch '/deliveries/deliveries_update_preferences/:id' => 'deliveries#deliveries_update_preferences', :as => 'deliveries_update_preferences'
  get '/deliveries/change_next_delivery_date/:id' => 'deliveries#change_next_delivery_date', :as => 'change_next_delivery_date'
  post '/deliveries/change_delivery_drink_quantity/:id' => 'deliveries#change_delivery_drink_quantity', :as => 'change_delivery_drink_quantity'
  post '/deliveries/remove_delivery_drink_quantity/:id' => 'deliveries#remove_delivery_drink_quantity'
  post '/deliveries/customer_delivery_messages/' => 'deliveries#customer_delivery_messages', :as => 'customer_delivery_messages'
  
  # routes to user drink preferences pages
  get '/drink_preferences/drink_profile/:id' => 'drink_preferences#drink_profile', :as => 'user_profile'
  get '/drink_preferences/drink_settings/:id' => 'drink_preferences#drink_settings', :as => 'user_drink_settings'
  post '/drink_preferences/profile/:id' => 'drink_preferences#create_drink_descriptors', :as => 'create_drink_descriptors'
  post '/drink_preferences/update_styles_preferences/:id' => 'drink_preferences#style_preferences', :as => 'user_style_preference'
  
  # routes to user activity pages
  get '/activities/user_ratings/:id' => 'activities#user_ratings', :as => 'recent_user_ratings'
  get '/activities/friend_ratings/:id' => 'activities#friend_ratings', :as => 'recent_friend_ratings'
  
  # routes to user supply pages
  get '/supplies/supply/:id' => 'supplies#supply', :as => 'user_supply'
  get '/supplies/load_rating_form_in_supply/:id' => 'supplies#load_rating_form_in_supply'
  get '/supplies/reload_drink_skip_rating/:id' => 'supplies#reload_drink_skip_rating'
  post '/supplies/move_drink_to_cooler/:id' => 'supplies#move_drink_to_cooler', :as => 'move_drink_to_cooler'
  get '/supplies/add_supply_drink/:id' => 'supplies#add_supply_drink', :as => 'add_supply_drink'
  get '/supplies/drink_search/:id(/:query)' => 'supplies#drink_search', :as => 'drink_search'
  post '/supplies/change_supply_drink/:id' => 'supplies#change_supply_drink', :as => 'change_supply_drink'
  post '/supplies/wishlist_removal/:id' => 'supplies#wishlist_removal', :as => 'wishlist_removal'
  get '/supplies/supply_removal/:id' => 'supplies#supply_removal', :as => 'supply_removal'
  post '/supplies/change_supply_drink_quantity/:id' => 'supplies#change_supply_drink_quantity', :as => 'change_supply_drink_quantity'
  post '/supplies/set_search_box_id/:id' => 'supplies#set_search_box_id', :as => 'set_search_box_id'

  # user ratings
  post '/ratings/:user_id/rate_drink_from_supply/:id' => 'ratings#rate_drink_from_supply', :as => 'rate_drink_from_supply'
  
  # orphan routes
  post '/users/customer_delivery_date/:id' => 'users#customer_delivery_date', :as => 'customer_delivery_date'
  patch '/users/customer_delivery_date/:id' => 'users#customer_delivery_date', :as => 'reset_customer_delivery_date'
  
  
  # user signup process
  get '/signup/getting_started/:id' => 'signup#getting_started', :as => 'getting_started'
  post '/signup/process_input/:id' => 'signup#process_input', :as => 'process_input'
  post '/signup/process_style_input/:id' => 'signup#process_style_input'
  post '/signup/process_drinks_per_week/:id' => 'signup#process_drinks_per_week'
  post '/signup/process_user_plan_choice/:id' => 'signup#process_user_plan_choice', :as => 'process_user_plan_choice'  
  patch '/signup/account_info_process' => 'signup#account_info_process', :as => 'account_info_process'
  
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
  
  post '/retailers/info_request' => 'retailers#info_request'
  resources :retailers
  
  get 'home/try_another_zip' => 'home#try_another_zip', :as => 'try_another_zip'
  get 'home/zip_code_response/:id' => 'home#zip_code_response'
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
  #get '/users/:user_id/ratings/new(.:format)' => 'ratings#new', :as => 'new_user_rating'
  
  # admin routes
  get 'porting' => 'porting#index'
  get 'reloads' => 'reloads#index'
  get 'admin/recommendations/next_delivery_drink/:id' => 'admin/recommendations#next_delivery_drink', :as => 'admin_next_delivery_drink'
  get 'admin/recommendations/change_user_view/:id' => 'admin/recommendations#change_user_view'
  get 'admin/recommendations/change_delivery_drink_quantity/:id' => 'admin/recommendations#change_delivery_drink_quantity', :as => 'admin_change_delivery_drink_quantity'
  get 'admin/recommendations/admin_user_delivery/:id' => 'admin/recommendations#admin_user_delivery', :as =>'admin_user_delivery'
  get 'admin/recommendations/admin_user_feedback/:id' => 'admin/recommendations#admin_user_feedback', :as =>'admin_user_feedback'
  get 'admin/recommendations/admin_review_delivery/:id' => 'admin/recommendations#admin_review_delivery', :as =>'admin_review_delivery'
  get 'admin/recommendations/admin_share_delivery_with_customer/:id' => 'admin/recommendations#admin_share_delivery_with_customer', :as =>'admin_share_delivery_with_customer'
  post 'admin/recommendations/admin_delivery_note/:id' => 'admin/recommendations#admin_delivery_note', :as =>'admin_delivery_note'
  post 'admin/fulfillment/admin_confirm_delivery/:id' => 'admin/fulfillment#admin_confirm_delivery', :as =>'admin_confirm_delivery'
  get 'admin/beers/current_beers' => 'admin/beers#current_beers', :as => 'admin_current_beers', :path => "/currentbeers"
  put 'admin/breweries/update' => 'admin/breweries#update'
  get 'admin/breweries/alt_names/:id' => 'admin/breweries#alt_brewery_name', :as => 'admin_alt_brewery_names'
  post 'admin/breweries/alt_names' => 'admin/breweries#create_alt_brewery', :as => 'admin_create_brewery_names'
  patch 'admin/breweries/delete_alt_name/:id' => 'admin/breweries#delete_alt_brewery_name', :as => 'admin_delete_alt_brewery_name'
  get 'admin/beers/alt_names/:id' => 'admin/beers#alt_beer_name', :as => 'admin_alt_beer_names'
  post 'admin/beers/alt_names' => 'admin/beers#create_alt_beer', :as => 'admin_create_beer_names'
  patch 'admin/beers/delete_alt_name/:id' => 'admin/beers#delete_alt_beer_name', :as => 'admin_delete_alt_beer_name'
  get 'admin/beers/delete_beer_prep/:brewery_id/:id' => 'admin/beers#delete_beer_prep', :as => 'admin_delete_beer_prep'
  patch 'admin/beers/delete_beer/:brewery_id/:id' => 'admin/beers#delete_beer', :as => 'admin_delete_beer'
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
