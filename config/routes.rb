Rails.application.routes.draw do
  
  devise_for :users, controllers: { invitations: "invitations", 
                                    omniauth_callbacks: "authentications",
                                    passwords: "passwords" }
  devise_scope :user do
    get 'users/invitation/invite_mate/:id' => 'invitations#invite_mate', :as => 'invite_mate'
    get '/users/invitation/invite_mate/users/invitation/check_invited_mate_status/:id' => 'invitations#check_invited_mate_status', :constraints => { :id => /[^\/]+/ }
    post 'users/invitation/process_mate_invite' => 'invitations#process_mate_invite', :as => 'process_mate_invite'
    get 'users/invitation/invite_friend/:id' => 'invitations#invite_friend', :as => 'invite_friend'
    get '/users/invitation/invite_friend/users/invitation/check_invited_mate_status/:id' => 'invitations#check_invited_friend_status', :constraints => { :id => /[^\/]+/ }
    post 'users/invitation/process_friend_invite' => 'invitations#process_friend_invite', :as => 'process_friend_invite'
  end
  
  resources :users do
    resources :drinks, :ratings, :rewards, :trackings   
  end
  
  resources :user_addresses
  
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
    resources :users, :user_beer_ratings, :recommendations, :inventories, :disti_inventories, :fulfillment
  end
  
  namespace :admin do
    resources :breweries do
      resources :beers
    end
  end
  
  root :to => 'home#index'
  # routes to user profile pages
  get '/users/first_password/accept' => 'users#first_password', :as => 'first_password'
  patch '/users/process_first_password/:id' => 'users#process_first_password', :as => 'process_first_password'
  
  get '/users/user_account_add_guest/:id' => 'users#user_account_add_guest', :as => 'user_account_add_guest'
  get '/users/account_settings_membership/:id' => 'users#account_settings_membership', :as => 'account_settings_membership'  
  get '/users/account_settings_profile/:id' => 'users#account_settings_profile', :as => 'account_settings_profile' 
  get '/users/account_settings_mates/:id' => 'users#account_settings_mates', :as => 'account_settings_mates'
  get '/users/send_mate_invite_reminder/:id' => 'users#send_mate_invite_reminder', :as => 'send_mate_invite_reminder'
  get '/users/drop_mate/:id' => 'users#drop_mate'
  get '/users/account_settings_cc/:id' => 'users#account_settings_cc', :as => 'account_settings_cc'
  get '/users/plan_rewewal_update/:id' => 'users#plan_rewewal_update', :as => 'plan_rewewal_update' 
  post '/users/process_user_plan_change/:id' => 'users#process_user_plan_change', :as => 'process_user_plan_change'
  patch '/users/update_profile/:id' => 'users#update_profile', :as => 'update_user_profile'
  post '/users/update_home_address/:id' => 'users#update_home_address'
  patch '/users/update_password/:id' => 'users#update_password'
  post '/users/choose_plan/:id' => 'users#choose_plan', :as => 'choose_plan'
  post '/stripe-webhooks' => 'users#stripe_webhooks'
  post 'users/add_new_card/:id' => 'users#add_new_card', :as => 'add_new_card'
  get 'users/delete_credit_card/:id' => 'users#delete_credit_card', :as => 'delete_credit_card'
  post '/users/username_verification/:id' => 'users#username_verification'
   
  # routes to user deliveries pages
  get '/delivery_settings/index/:id' => 'delivery_settings#index', :as => 'user_delivery_settings'
  get '/delivery_settings/delivery_location' => 'delivery_settings#delivery_location', :as => 'user_delivery_settings_location'
  get '/delivery_settings/change_delivery_time' => 'delivery_settings#change_delivery_time', :as => 'change_delivery_time'
  get '/delivery_settings/total_estimate' => 'delivery_settings#total_estimate', :as => 'user_delivery_settings_total_estimate'
  post '/delivery_settings/deliveries_update_estimates/:id' => 'delivery_settings#deliveries_update_estimates', :as => 'deliveries_update_estimates'
  patch '/delivery_settings/deliveries_update_preferences/:id' => 'delivery_settings#deliveries_update_preferences', :as => 'deliveries_update_preferences'
  get '/delivery_settings/change_next_delivery_date/:id' => 'delivery_settings#change_next_delivery_date', :as => 'change_next_delivery_date'
  post '/delivery_settings/change_delivery_drink_quantity/:id' => 'delivery_settings#change_delivery_drink_quantity', :as => 'change_delivery_drink_quantity'
  post '/delivery_settings/remove_delivery_drink_quantity/:id' => 'delivery_settings#remove_delivery_drink_quantity'
  post '/delivery_settings/customer_delivery_messages/' => 'delivery_settings#customer_delivery_messages', :as => 'customer_delivery_messages'

  # routes to user drink preferences pages
  get '/drink_preferences/drink_profile/:id' => 'drink_preferences#drink_profile', :as => 'user_profile'
  get '/drink_preferences/drink_settings/:id' => 'drink_preferences#drink_settings', :as => 'user_drink_settings'
  post '/drink_preferences/profile/:id' => 'drink_preferences#create_drink_descriptors', :as => 'create_drink_descriptors'
  
  # routes to user style settings pages
  get '/style_settings/index/:id' => 'style_settings#index', :as => 'user_style_settings'
  post '/style_settings/update_styles_preferences/:id' => 'style_settings#update_styles_preferences', :as => 'user_style_preference'
  
  # routes to connections pages
  get '/connections/manage_friends' => 'connections#manage_friends', :as => 'manage_friends'
  get '/connections/find_friends/:id' => 'connections#find_friends', :as => 'find_friends'
  get '/connections/friend_search/:id(/:query)' => 'connections#process_friend_search', :as => 'friend_search'
  get '/connections/add_connection/:id' => 'connections#add_connection'
  get '/connections/remove_connection/:id' => 'connections#remove_connection'
  get '/connections/invite_connection_reminder/:id' => 'connections#invite_connection_reminder', :as => 'invite_connection_reminder'
  post '/connections/process_friend_changes_on_find_page/:id' => 'connections#process_friend_changes_on_find_page'
  
  # routes to drink pages
  get '/drinks/deliveries' => 'drinks#deliveries', :as => 'user_deliveries'
  get '/drinks/cellar' => 'drinks#cellar', :as => 'user_cellar'
  get '/drinks/wishlist' => 'drinks#wishlist', :as => 'user_wishlist'
  get '/drinks/supply/:id' => 'drinks#supply', :as => 'user_supply'
  get '/drinks/load_rating_form_in_supply/:id' => 'drinks#load_rating_form_in_supply'
  get '/drinks/reload_drink_skip_rating/:id' => 'drinks#reload_drink_skip_rating'
  get '/drinks/move_drink_to_cellar/:id' => 'drinks#move_drink_to_cellar', :as => 'move_drink_to_cellar'
  get '/drinks/add_supply_drink/:id' => 'drinks#add_supply_drink', :as => 'add_supply_drink'
  get '/drinks/drink_search/:id(/:query)' => 'drinks#drink_search', :as => 'drink_search'
  post '/drinks/add_cellar_drink/:id' => 'drinks#add_cellar_drink', :as => 'add_cellar_drink'
  get '/drinks/change_cellar_drink_quantity/:id' => 'drinks#change_cellar_drink_quantity'
  post '/drinks/add_wishlist_drink/:id' => 'drinks#add_wishlist_drink', :as => 'add_wishlist_drink'
  get '/drinks/wishlist_removal/:id' => 'drinks#wishlist_removal', :as => 'wishlist_removal'
  get '/drinks/supply_removal/:id' => 'drinks#supply_removal', :as => 'supply_removal'
  get '/drinks/change_delivery_drink_quantity/:id' => 'drinks#change_delivery_drink_quantity'
  post '/drinks/set_search_box_id/:id' => 'drinks#set_search_box_id', :as => 'set_search_box_id'

  # user ratings routes
  post '/ratings/:user_id/rate_drink_from_supply/:id' => 'ratings#rate_drink_from_supply', :as => 'rate_drink_from_supply'
  get '/ratings/user_ratings/:id' => 'ratings#user_ratings', :as => 'recent_user_ratings'
  get '/ratings/friend_ratings/:id' => 'ratings#friend_ratings', :as => 'recent_friend_ratings'
  
  # rewards routes
  #get '/rewards/index/:id' => 'rewards#index', :as => 'user_rewards'
  
  # orphan routes
  post '/users/customer_delivery_date/:id' => 'users#customer_delivery_date', :as => 'customer_delivery_date'
  patch '/users/customer_delivery_date/:id' => 'users#customer_delivery_date', :as => 'reset_customer_delivery_date'
  
  # user signup process
  get '/signup/home_address_getting_started' => 'signup#home_address_getting_started', :as => 'home_address_getting_started'
  post '/signup/process_home_address_getting_started' => 'signup#process_home_address_getting_started', :as => 'process_home_address_getting_started'

  get '/signup/delivery_address_getting_started' => 'signup#delivery_address_getting_started', :as => 'delivery_address_getting_started'
   
  get '/signup/drink_choice_getting_started' => 'signup#drink_choice_getting_started', :as => 'drink_choice_getting_started'
  post '/signup/process_drink_choice_getting_started/:id' => 'signup#process_drink_choice_getting_started', :as => 'process_drink_choice_getting_started'
  
  get '/signup/drink_journey_getting_started' => 'signup#drink_journey_getting_started', :as => 'drink_journey_getting_started'
  post '/signup/process_drink_journey_getting_started' => 'signup#process_drink_journey_getting_started', :as => 'process_drink_journey_getting_started'
  
  get '/signup/drink_style_likes_getting_started' => 'signup#drink_style_likes_getting_started', :as => 'drink_style_likes_getting_started'
  post '/signup/process_drink_style_likes_getting_started' => 'signup#process_drink_style_likes_getting_started', :as => 'process_drink_style_likes_getting_started'
  get '/signup/drink_style_dislikes_getting_started' => 'signup#drink_style_dislikes_getting_started', :as => 'drink_style_dislikes_getting_started'

  get '/signup/drinks_weekly_getting_started' => 'signup#drinks_weekly_getting_started', :as => 'drinks_weekly_getting_started'
  post '/signup/process_drinks_weekly_getting_started/:id' => 'signup#process_drinks_weekly_getting_started', :as => 'process_drinks_weekly_getting_started'

  get '/signup/drinks_large_getting_started' => 'signup#drinks_large_getting_started', :as => 'drinks_large_getting_started'
  post '/signup/process_drinks_large_getting_started/:id' => 'signup#process_drinks_large_getting_started', :as => 'process_drinks_large_getting_started'
    
  get '/signup/delivery_preferences_getting_started' => 'signup#delivery_preferences_getting_started', :as => 'delivery_preferences_getting_started'
  get '/signup/choose_delivery_time' => 'signup#choose_delivery_time', :as => 'choose_delivery_time'
  
  get '/signup/account_membership_getting_started' => 'signup#account_membership_getting_started', :as => 'account_membership_getting_started'
  post '/signup/process_account_membership_getting_started/:id' => 'signup#process_account_membership_getting_started', :as => 'process_account_membership_getting_started'
  
  get '/signup/signup_thank_you/:id' => 'signup#signup_thank_you', :as => 'signup_thank_you'
  
  post '/signup/username_verification/:id' => 'signup#username_verification', :as => 'username_verification'
  
  post '/signup/process_style_input/:id' => 'signup#process_style_input'
  post '/signup/process_user_plan_choice/:id' => 'signup#process_user_plan_choice', :as => 'process_user_plan_choice'  
  patch '/signup/account_info_process' => 'signup#account_info_process', :as => 'account_info_process'
  
  # user early signup process
  get '/early_signup/invitation_code' => 'early_signup#invitation_code', :as => 'invitation_code'
  post '/early_signup/process_invitation_code/:id' => 'early_signup#process_invitation_code', :as => 'process_invitation_code'
  
  post '/early_signup/request_code' => 'early_signup#request_code', :as => 'request_code'
  get '/early_signup/request_verification/:id' => 'early_signup#request_verification', :as => 'request_verification'
  
  get '/early_signup/account_info/:id' => 'early_signup#account_info', :as => 'account_info'
  post '/early_signup/process_account_info' => 'early_signup#process_account_info', :as => 'process_account_info'
  
  get '/early_signup/billing_info/:id' => 'early_signup#billing_info', :as => 'billing_info'
  post '/early_signup/process_billing_info/:id' => 'early_signup#process_billing_info', :as => 'process_billing_info'
  
  get '/early_signup/early_signup_confirmation/:id' => 'early_signup#early_signup_confirmation', :as => 'early_signup_confirmation'
  
  get '/early_signup/early_customer_password_response/:id' => 'early_signup#early_customer_password_response', :as => 'early_customer_password_response'
  
  # privacy and terms routes
  get 'privacy' => 'home#privacy', :as => "privacy"
  get 'terms' => 'home#terms', :as => "terms"
  
  # routes--mostly old for retailers
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
  post 'beers/change_cellar_setting/:id' => 'beers#change_cellar_setting', :as => 'change_cellar_setting'
  get 'breweries/:brewery_id/beers/beers/data' => 'beers#data', :defaults => { :format => 'json'}
  #get '/users/:user_id/ratings/new(.:format)' => 'ratings#new', :as => 'new_user_rating'
  
  # admin testing routes
  get 'porting' => 'porting#index'
  get 'reloads' => 'reloads#index'
  get 'reloads/data', :defaults => { :format => 'json' }
  
  # admin recommendation routes
  get 'admin/recommendations/admin_account_delivery/:id' => 'admin/recommendations#admin_account_delivery'
  get 'admin/recommendations/change_user_view/:id' => 'admin/recommendations#change_user_view'
  get 'admin/recommendations/change_delivery_drink_quantity/:id' => 'admin/recommendations#change_delivery_drink_quantity', :as => 'admin_change_delivery_drink_quantity'
  get 'admin/recommendations/admin_user_delivery/:id' => 'admin/recommendations#admin_user_delivery', :as =>'admin_user_delivery'
  get 'admin/recommendations/admin_user_feedback/:id' => 'admin/recommendations#admin_user_feedback', :as =>'admin_user_feedback'
  get 'admin/recommendations/admin_review_delivery/:id' => 'admin/recommendations#admin_review_delivery', :as =>'admin_review_delivery'
  get 'admin/recommendations/admin_share_delivery_with_customer/:id' => 'admin/recommendations#admin_share_delivery_with_customer', :as =>'admin_share_delivery_with_customer'
  post 'admin/recommendations/admin_delivery_note/:id' => 'admin/recommendations#admin_delivery_note', :as =>'admin_delivery_note'
  post 'admin/fulfillment/admin_confirm_delivery/:id' => 'admin/fulfillment#admin_confirm_delivery', :as =>'admin_confirm_delivery'
  
  # admin inventory routes
  namespace :admin do
      get 'order_requests' => 'inventories#order_requests'
      get 'disti_orders' => 'disti_inventories#disti_orders'
      get 'disti_inventories_change' => 'disti_inventories#disti_inventories_change', :as => 'disti_inventories_change'
      post 'disti_inventories_import' => 'disti_inventories#import_disti_inventory', :as => 'import_disti_inventory'
      post 'disti_inventories_update' => 'disti_inventories#update_disti_inventory', :as => 'update_disti_inventory'
  end
  
  
  # admin drink DB management routes
  get 'admin/beers/current_beers' => 'admin/beers#current_beers', :as => 'admin_current_beers', :path => "/currentbeers"
  post 'admin/beers/remove_multiple_drinks/:id' => 'admin/beers#remove_multiple_drinks'
  put 'admin/breweries/update' => 'admin/breweries#update'
  get 'admin/breweries/alt_names/:id' => 'admin/breweries#alt_brewery_name', :as => 'admin_alt_brewery_names'
  get 'admin/breweries/merge_brewery_prep/:id' => 'admin/breweries#merge_brewery_prep', :as => 'admin_merge_brewery_prep'
  get 'admin/breweries/add_new_brewery/:id' => 'admin/breweries#add_new_brewery', :as => 'admin_add_new_brewery'
  get 'admin/breweries/delete_temp_brewery/:id' => 'admin/breweries#delete_temp_brewery', :as => 'admin_delete_temp_brewery'
  post 'admin/breweries/merge_breweries/:id' => 'admin/breweries#merge_breweries', :as => 'admin_merge_breweries'
  post 'admin/breweries/alt_names' => 'admin/breweries#create_alt_brewery', :as => 'admin_create_brewery_names'
  patch 'admin/breweries/delete_alt_name/:id' => 'admin/breweries#delete_alt_brewery_name', :as => 'admin_delete_alt_brewery_name'
  get 'admin/beers/alt_names/:id' => 'admin/beers#alt_beer_name', :as => 'admin_alt_beer_names'
  post 'admin/beers/alt_names' => 'admin/beers#create_alt_beer', :as => 'admin_create_beer_names'
  patch 'admin/beers/delete_alt_name/:id' => 'admin/beers#delete_alt_beer_name', :as => 'admin_delete_alt_beer_name'
  get 'admin/beers/delete_beer_prep/:brewery_id/:id' => 'admin/beers#delete_beer_prep', :as => 'admin_delete_beer_prep'
  patch 'admin/beers/delete_beer/:brewery_id/:id' => 'admin/beers#delete_beer', :as => 'admin_delete_beer'
  get 'admin/beers/delete_temp_beer/:brewery_id/:id' => 'admin/beers#delete_temp_beer', :as => 'admin_delete_temp_beer'
  get 'admin/needs_work_beers(.:format)' => 'admin/beers#show', :as => 'admin_needs_work_beers'
  get 'admin/beers/temp_drinks/:brewery_id/' => 'admin/beers#temp_drinks', :as => 'admin_brewery_temp_beers'
  get 'admin/beers/add_drink_to_brewery/:id/' => 'admin/beers#add_drink_to_brewery', :as => 'admin_add_drink_to_brewery'
  get 'admin/beers/delete_drink_from_brewery_prep/:id' => 'admin/beers#delete_drink_from_brewery_prep', :as => 'admin_delete_drink_from_brewery_prep'
  post 'admin/beers/delete_drink_from_brewery/:id/' => 'admin/beers#delete_drink_from_brewery', :as => 'admin_delete_drink_from_brewery'
  
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
