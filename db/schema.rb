# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170127194508) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admin_user_deliveries", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "beer_id"
    t.integer  "inventory_id"
    t.boolean  "new_drink"
    t.float    "projected_rating"
    t.string   "likes_style"
    t.integer  "quantity"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.boolean  "cellar"
    t.boolean  "large_format"
    t.integer  "delivery_id"
    t.text     "this_beer_descriptors"
    t.string   "beer_style_name_one"
    t.string   "beer_style_name_two"
    t.string   "recommendation_rationale"
    t.boolean  "is_hybrid"
  end

  create_table "alt_beer_names", force: :cascade do |t|
    t.string   "name"
    t.integer  "beer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "alt_brewery_names", force: :cascade do |t|
    t.string   "name"
    t.integer  "brewery_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "authentications", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "uid"
    t.string   "token"
    t.string   "token_secret"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.integer  "location_id"
    t.boolean  "auto_tweet"
  end

  create_table "beer_brewery_collabs", force: :cascade do |t|
    t.integer  "beer_id"
    t.integer  "brewery_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "beer_formats", force: :cascade do |t|
    t.integer  "beer_id"
    t.integer  "size_format_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  create_table "beer_locations", force: :cascade do |t|
    t.integer  "beer_id"
    t.integer  "location_id"
    t.integer  "tap_number"
    t.integer  "draft_board_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  create_table "beer_styles", force: :cascade do |t|
    t.string   "style_name"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.string   "style_image_url"
    t.boolean  "signup_beer"
    t.boolean  "signup_cider"
    t.boolean  "signup_beer_cider"
    t.boolean  "standard_list"
    t.integer  "style_order"
  end

  create_table "beer_type_relationships", force: :cascade do |t|
    t.integer  "beer_type_id"
    t.integer  "relationship_one"
    t.integer  "relationship_two"
    t.integer  "relationship_three"
    t.text     "rationale"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  create_table "beer_types", force: :cascade do |t|
    t.string   "beer_type_name"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "beer_style_id"
    t.string   "beer_type_short_name"
    t.string   "alt_one_beer_type_name"
    t.string   "alt_two_beer_type_name"
    t.boolean  "cellarable"
    t.text     "cellarable_info"
  end

  create_table "beers", force: :cascade do |t|
    t.string   "beer_name",            limit: 255
    t.string   "beer_type_old_name",   limit: 255
    t.float    "beer_rating_one"
    t.integer  "number_ratings_one"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "brewery_id"
    t.float    "beer_abv"
    t.integer  "beer_ibu"
    t.string   "beer_image",           limit: 255
    t.string   "speciality_notice",    limit: 255
    t.text     "original_descriptors"
    t.text     "hops"
    t.text     "grains"
    t.text     "brewer_description"
    t.integer  "beer_type_id"
    t.float    "beer_rating_two"
    t.integer  "number_ratings_two"
    t.float    "beer_rating_three"
    t.integer  "number_ratings_three"
    t.boolean  "rating_one_na"
    t.boolean  "rating_two_na"
    t.boolean  "rating_three_na"
    t.boolean  "user_addition"
    t.integer  "touched_by_user"
    t.boolean  "collab"
    t.string   "short_beer_name"
    t.boolean  "vetted"
    t.integer  "touched_by_location"
    t.text     "cellar_note"
  end

  create_table "breweries", force: :cascade do |t|
    t.string   "brewery_name",        limit: 255
    t.string   "brewery_city",        limit: 255
    t.string   "brewery_state_short", limit: 255
    t.string   "brewery_url",         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "image"
    t.integer  "brewery_beers"
    t.string   "short_brewery_name"
    t.boolean  "collab"
    t.boolean  "vetted"
    t.string   "brewery_state_long"
    t.string   "facebook_url"
    t.string   "twitter_url"
  end

  create_table "craft_stages", force: :cascade do |t|
    t.string   "stage_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "customer_delivery_changes", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "delivery_id"
    t.integer  "user_delivery_id"
    t.integer  "original_quantity"
    t.integer  "new_quantity"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.integer  "beer_id"
    t.boolean  "change_noted"
  end

  create_table "customer_delivery_messages", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "delivery_id"
    t.text     "message"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.boolean  "admin_notified"
  end

  create_table "deliveries", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "delivery_date"
    t.decimal  "subtotal",                         precision: 6, scale: 2
    t.decimal  "sales_tax",                        precision: 6, scale: 2
    t.decimal  "total_price",                      precision: 6, scale: 2
    t.string   "status"
    t.datetime "created_at",                                               null: false
    t.datetime "updated_at",                                               null: false
    t.text     "admin_delivery_review_note"
    t.text     "admin_delivery_confirmation_note"
    t.boolean  "delivery_change_confirmation"
    t.boolean  "customer_has_previous_packaging"
    t.text     "final_delivery_notes"
    t.boolean  "share_admin_prep_with_user"
  end

  create_table "delivery_preferences", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "drinks_per_week"
    t.text     "additional"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "price_estimate"
    t.datetime "first_delivery_date"
    t.integer  "drink_option_id"
    t.integer  "max_large_format"
    t.integer  "max_cellar"
  end

  create_table "draft_boards", force: :cascade do |t|
    t.integer  "location_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "draft_details", force: :cascade do |t|
    t.integer  "drink_size"
    t.decimal  "drink_cost",       precision: 5, scale: 2
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.integer  "beer_location_id"
  end

  create_table "drink_options", force: :cascade do |t|
    t.string   "drink_option_name"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "friends", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "friend_id"
    t.boolean  "confirmed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "inventories", force: :cascade do |t|
    t.integer  "stock"
    t.integer  "reserved"
    t.integer  "order_queue"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.integer  "size_format_id"
    t.integer  "beer_id"
    t.decimal  "drink_price",    precision: 5, scale: 2
    t.decimal  "drink_cost",     precision: 5, scale: 2
    t.integer  "limit_per"
  end

  create_table "invitation_requests", force: :cascade do |t|
    t.string   "email"
    t.string   "status"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "first_name"
    t.string   "zip_code"
    t.string   "city"
    t.string   "state"
    t.boolean  "delivery_ok"
    t.datetime "birthday"
  end

  create_table "locations", force: :cascade do |t|
    t.string   "name",            limit: 255
    t.string   "homepage",        limit: 255
    t.string   "beerpage",        limit: 255
    t.datetime "last_scanned"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "image_url"
    t.string   "short_name"
    t.string   "neighborhood"
    t.string   "logo_small"
    t.string   "logo_med"
    t.string   "logo_large"
    t.boolean  "ignore_location"
    t.string   "facebook_url"
    t.string   "twitter_url"
    t.string   "address"
    t.string   "phone_number"
    t.string   "email"
    t.string   "hours_one"
    t.string   "hours_two"
    t.string   "hours_three"
    t.string   "hours_four"
    t.string   "logo_holder"
    t.string   "image_holder"
  end

  create_table "pg_search_documents", force: :cascade do |t|
    t.text     "content"
    t.integer  "searchable_id"
    t.string   "searchable_type"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "pg_search_documents", ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable_type_and_searchable_id", using: :btree

  create_table "removed_beer_locations", force: :cascade do |t|
    t.integer  "beer_id"
    t.integer  "location_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "removed_at"
  end

  create_table "reward_points", force: :cascade do |t|
    t.integer  "user_id"
    t.float    "total_points"
    t.float    "transaction_points"
    t.integer  "reward_transaction_type_id"
    t.integer  "beer_id"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "reward_transaction_types", force: :cascade do |t|
    t.string   "reward_title"
    t.string   "reward_description"
    t.string   "reward_impact"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  create_table "roles", force: :cascade do |t|
    t.string   "role_name",  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "size_formats", force: :cascade do |t|
    t.string   "format_name"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "special_codes", force: :cascade do |t|
    t.string   "special_code"
    t.integer  "user_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "subscriptions", force: :cascade do |t|
    t.string   "subscription_level"
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.decimal  "subscription_cost",          precision: 5, scale: 2
    t.string   "subscription_name"
    t.integer  "subscription_months_length"
    t.decimal  "extra_delivery_cost",        precision: 5, scale: 2
  end

  create_table "supply_types", force: :cascade do |t|
    t.string   "designation"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "taggings", force: :cascade do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context",       limit: 128
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true, using: :btree
  add_index "taggings", ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context", using: :btree

  create_table "tags", force: :cascade do |t|
    t.string  "name"
    t.integer "taggings_count", default: 0
  end

  add_index "tags", ["name"], name: "index_tags_on_name", unique: true, using: :btree

  create_table "temp_beer_brewery_collabs", force: :cascade do |t|
    t.integer  "beer_id"
    t.integer  "brewery_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "temp_beers", force: :cascade do |t|
    t.string   "beer_name",            limit: 255
    t.string   "beer_type_old_name",   limit: 255
    t.float    "beer_rating_one"
    t.integer  "number_ratings_one"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "brewery_id"
    t.float    "beer_abv"
    t.integer  "beer_ibu"
    t.string   "beer_image",           limit: 255
    t.string   "speciality_notice",    limit: 255
    t.text     "original_descriptors"
    t.text     "hops"
    t.text     "grains"
    t.text     "brewer_description"
    t.integer  "beer_type_id"
    t.float    "beer_rating_two"
    t.integer  "number_ratings_two"
    t.float    "beer_rating_three"
    t.integer  "number_ratings_three"
    t.boolean  "rating_one_na"
    t.boolean  "rating_two_na"
    t.boolean  "rating_three_na"
    t.boolean  "user_addition"
    t.integer  "touched_by_user"
    t.boolean  "collab"
    t.string   "short_beer_name"
    t.boolean  "vetted"
    t.integer  "touched_by_location"
    t.text     "cellar_note"
  end

  create_table "temp_breweries", force: :cascade do |t|
    t.string   "brewery_name",        limit: 255
    t.string   "brewery_city",        limit: 255
    t.string   "brewery_state_short", limit: 255
    t.string   "brewery_url",         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "image"
    t.integer  "brewery_beers"
    t.string   "short_brewery_name"
    t.boolean  "collab"
    t.boolean  "vetted"
    t.string   "brewery_state_long"
    t.string   "facebook_url"
    t.string   "twitter_url"
  end

  create_table "temp_breweries_temp_beers", force: :cascade do |t|
    t.string   "beer_name",            limit: 255
    t.string   "beer_type_old_name",   limit: 255
    t.float    "beer_rating_one"
    t.integer  "number_ratings_one"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "brewery_id"
    t.float    "beer_abv"
    t.integer  "beer_ibu"
    t.string   "beer_image",           limit: 255
    t.string   "speciality_notice",    limit: 255
    t.text     "original_descriptors"
    t.text     "hops"
    t.text     "grains"
    t.text     "brewer_description"
    t.integer  "beer_type_id"
    t.float    "beer_rating_two"
    t.integer  "number_ratings_two"
    t.float    "beer_rating_three"
    t.integer  "number_ratings_three"
    t.boolean  "rating_one_na"
    t.boolean  "rating_two_na"
    t.boolean  "rating_three_na"
    t.boolean  "user_addition"
    t.integer  "touched_by_user"
    t.boolean  "collab"
    t.string   "short_beer_name"
    t.boolean  "vetted"
    t.integer  "touched_by_location"
    t.text     "cellar_note"
  end

  create_table "user_beer_ratings", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "beer_id"
    t.float    "user_beer_rating"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "drank_at",            limit: 255
    t.datetime "rated_on"
    t.float    "projected_rating"
    t.text     "comment"
    t.text     "current_descriptors"
    t.integer  "beer_type_id"
    t.boolean  "admin_vetted"
  end

  create_table "user_deliveries", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "inventory_id"
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
    t.boolean  "new_drink"
    t.integer  "beer_id"
    t.float    "projected_rating"
    t.string   "likes_style"
    t.integer  "quantity"
    t.integer  "delivery_id"
    t.boolean  "cellar"
    t.boolean  "large_format"
    t.decimal  "drink_cost",               precision: 5, scale: 2
    t.decimal  "drink_price",              precision: 5, scale: 2
    t.text     "this_beer_descriptors"
    t.string   "beer_style_name_one"
    t.string   "beer_style_name_two"
    t.string   "recommendation_rationale"
    t.boolean  "is_hybrid"
  end

  create_table "user_delivery_addresses", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "address_one"
    t.string   "address_two"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.text     "special_instructions"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.boolean  "location_type"
  end

  create_table "user_drink_recommendations", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "beer_id"
    t.float    "projected_rating"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.boolean  "new_drink"
    t.string   "likes_style"
    t.text     "this_beer_descriptors"
    t.string   "beer_style_name_one"
    t.string   "beer_style_name_two"
    t.string   "recommendation_rationale"
    t.boolean  "is_hybrid"
  end

  create_table "user_fav_drinks", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "beer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "drink_rank"
  end

  create_table "user_locations", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "location_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.boolean  "owner"
  end

  create_table "user_notification_preferences", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "notification_one"
    t.boolean  "preference_one"
    t.float    "threshold_one"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.string   "notification_two"
    t.boolean  "preference_two"
    t.float    "threshold_two"
  end

  create_table "user_style_preferences", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "beer_style_id"
    t.string   "user_preference"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  create_table "user_subscriptions", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "subscription_id"
    t.datetime "active_until"
    t.string   "stripe_customer_number"
    t.string   "stripe_subscription_number"
    t.boolean  "current_trial"
    t.boolean  "trial_ended"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.integer  "auto_renew_subscription_id"
    t.integer  "deliveries_this_period"
    t.integer  "total_deliveries"
  end

  create_table "user_supplies", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "beer_id"
    t.integer  "supply_type_id"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.integer  "quantity"
    t.text     "cellar_note"
    t.float    "projected_rating"
    t.text     "this_beer_descriptors"
    t.string   "beer_style_name_one"
    t.string   "beer_style_name_two"
    t.string   "recommendation_rationale"
    t.boolean  "is_hybrid"
    t.string   "likes_style"
    t.boolean  "admin_vetted"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "", null: false
    t.string   "encrypted_password",     limit: 255, default: ""
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "role_id"
    t.string   "username"
    t.string   "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer  "invitation_limit"
    t.integer  "invited_by_id"
    t.string   "invited_by_type"
    t.integer  "invitations_count",                  default: 0
    t.string   "first_name"
    t.integer  "craft_stage_id"
    t.string   "last_name"
    t.integer  "getting_started_step"
    t.boolean  "beta_tester"
    t.datetime "birthday"
    t.string   "user_graphic"
    t.string   "user_color"
    t.string   "special_code"
    t.string   "tpw"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["invitation_token"], name: "index_users_on_invitation_token", unique: true, using: :btree
  add_index "users", ["invitations_count"], name: "index_users_on_invitations_count", using: :btree
  add_index "users", ["invited_by_id"], name: "index_users_on_invited_by_id", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "wishlists", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "beer_id"
    t.datetime "removed_at"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.boolean  "admin_vetted"
  end

  create_table "zip_codes", force: :cascade do |t|
    t.string   "zip_code"
    t.boolean  "covered"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "city"
    t.string   "state"
  end

end
