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

ActiveRecord::Schema.define(version: 20180815230455) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "account_deliveries", id: :serial, force: :cascade do |t|
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "beer_id"
    t.integer "quantity"
    t.integer "delivery_id"
    t.boolean "cellar"
    t.boolean "large_format"
    t.decimal "drink_price", precision: 5, scale: 2
    t.integer "times_rated"
    t.boolean "moved_to_cellar_supply"
    t.integer "size_format_id"
    t.integer "inventory_id"
  end

  create_table "accounts", id: :serial, force: :cascade do |t|
    t.string "account_type"
    t.integer "number_of_users"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "delivery_location_user_address_id"
    t.integer "delivery_zone_id"
    t.integer "delivery_frequency"
    t.integer "shipping_zone_id"
    t.boolean "knird_live_trial"
  end

  create_table "admin_inventory_transactions", id: :serial, force: :cascade do |t|
    t.integer "admin_account_delivery_id"
    t.integer "inventory_id"
    t.integer "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ahoy_events", id: :serial, force: :cascade do |t|
    t.integer "visit_id"
    t.integer "user_id"
    t.string "name"
    t.jsonb "properties"
    t.datetime "time"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
  end

  create_table "ahoy_visits", id: :serial, force: :cascade do |t|
    t.string "visit_token"
    t.string "visitor_token"
    t.integer "user_id"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.string "referring_domain"
    t.string "search_keyword"
    t.text "landing_page"
    t.string "browser"
    t.string "os"
    t.string "device_type"
    t.string "country"
    t.string "region"
    t.string "city"
    t.string "utm_source"
    t.string "utm_medium"
    t.string "utm_term"
    t.string "utm_content"
    t.string "utm_campaign"
    t.datetime "started_at"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
  end

  create_table "alt_beer_names", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "beer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "alt_brewery_names", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "brewery_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "authentications", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "provider"
    t.string "uid"
    t.string "token"
    t.string "token_secret"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "location_id"
    t.boolean "auto_tweet"
  end

  create_table "beer_brewery_collabs", id: :serial, force: :cascade do |t|
    t.integer "beer_id"
    t.integer "brewery_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "beer_formats", id: :serial, force: :cascade do |t|
    t.integer "beer_id"
    t.integer "size_format_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "beer_locations", id: :serial, force: :cascade do |t|
    t.integer "beer_id"
    t.integer "location_id"
    t.integer "tap_number"
    t.integer "draft_board_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "beer_styles", id: :serial, force: :cascade do |t|
    t.string "style_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "style_image_url"
    t.boolean "signup_beer"
    t.boolean "signup_cider"
    t.boolean "signup_beer_cider"
    t.boolean "standard_list"
    t.integer "style_order"
    t.integer "master_style_id"
  end

  create_table "beer_type_relationships", id: :serial, force: :cascade do |t|
    t.integer "beer_type_id"
    t.integer "relationship_one"
    t.integer "relationship_two"
    t.integer "relationship_three"
    t.text "rationale"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "beer_types", id: :serial, force: :cascade do |t|
    t.string "beer_type_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "beer_style_id"
    t.string "beer_type_short_name"
    t.string "alt_one_beer_type_name"
    t.string "alt_two_beer_type_name"
    t.boolean "cellarable"
    t.text "cellarable_info"
  end

  create_table "beers", id: :serial, force: :cascade do |t|
    t.string "beer_name", limit: 255
    t.string "beer_type_old_name", limit: 255
    t.float "beer_rating_one"
    t.integer "number_ratings_one"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "brewery_id"
    t.float "beer_abv"
    t.integer "beer_ibu"
    t.string "beer_image", limit: 255
    t.string "speciality_notice", limit: 255
    t.text "original_descriptors"
    t.text "hops"
    t.text "grains"
    t.text "brewer_description"
    t.integer "beer_type_id"
    t.float "beer_rating_two"
    t.integer "number_ratings_two"
    t.float "beer_rating_three"
    t.integer "number_ratings_three"
    t.boolean "rating_one_na"
    t.boolean "rating_two_na"
    t.boolean "rating_three_na"
    t.boolean "user_addition"
    t.integer "touched_by_user"
    t.boolean "collab"
    t.string "short_beer_name"
    t.boolean "vetted"
    t.integer "touched_by_location"
    t.text "cellar_note"
    t.boolean "gluten_free"
    t.string "slug"
    t.index ["slug"], name: "index_beers_on_slug", unique: true
  end

  create_table "blazer_audits", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "query_id"
    t.text "statement"
    t.string "data_source"
    t.datetime "created_at"
  end

  create_table "blazer_checks", id: :serial, force: :cascade do |t|
    t.integer "creator_id"
    t.integer "query_id"
    t.string "state"
    t.string "schedule"
    t.text "emails"
    t.string "check_type"
    t.text "message"
    t.datetime "last_run_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "blazer_dashboard_queries", id: :serial, force: :cascade do |t|
    t.integer "dashboard_id"
    t.integer "query_id"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "blazer_dashboards", id: :serial, force: :cascade do |t|
    t.integer "creator_id"
    t.text "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "blazer_queries", id: :serial, force: :cascade do |t|
    t.integer "creator_id"
    t.string "name"
    t.text "description"
    t.text "statement"
    t.string "data_source"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "blog_posts", force: :cascade do |t|
    t.string "title"
    t.string "subtitle"
    t.string "status"
    t.text "content"
    t.string "image_url"
    t.integer "user_id"
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "beer_id"
    t.string "untappd_url"
    t.string "ba_url"
    t.string "slug"
    t.text "content_opening"
    t.string "brewers_image_url"
  end

  create_table "breweries", id: :serial, force: :cascade do |t|
    t.string "brewery_name", limit: 255
    t.string "brewery_city", limit: 255
    t.string "brewery_state_short", limit: 255
    t.string "brewery_url", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "image"
    t.integer "brewery_beers"
    t.string "short_brewery_name"
    t.boolean "collab"
    t.boolean "vetted"
    t.string "brewery_state_long"
    t.string "facebook_url"
    t.string "twitter_url"
    t.text "brewery_description"
    t.string "founded"
    t.string "slug"
    t.string "instagram_url"
    t.index ["slug"], name: "index_breweries_on_slug", unique: true
  end

  create_table "coupon_rules", force: :cascade do |t|
    t.bigint "coupon_id"
    t.decimal "original_value_start"
    t.decimal "original_value_end"
    t.float "add_value_percent"
    t.decimal "add_value_amount"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["coupon_id"], name: "index_coupon_rules_on_coupon_id"
  end

  create_table "coupons", force: :cascade do |t|
    t.string "code"
    t.datetime "valid_from"
    t.datetime "valid_till"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "craft_stages", id: :serial, force: :cascade do |t|
    t.string "stage_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "credits", id: :serial, force: :cascade do |t|
    t.float "total_credit"
    t.float "transaction_credit"
    t.string "transaction_type"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_credits_on_account_id"
  end

  create_table "curation_requests", id: :serial, force: :cascade do |t|
    t.integer "account_id"
    t.string "drink_type"
    t.integer "number_of_beers"
    t.integer "number_of_large_drinks"
    t.datetime "delivery_date"
    t.string "additional_requests"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "drink_option_id"
    t.integer "user_id"
    t.integer "number_of_ciders"
    t.integer "number_of_glasses"
    t.index ["account_id"], name: "index_curation_requests_on_account_id"
    t.index ["user_id"], name: "index_curation_requests_on_user_id"
  end

  create_table "customer_delivery_changes", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "delivery_id"
    t.integer "user_delivery_id"
    t.integer "original_quantity"
    t.integer "new_quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "beer_id"
    t.boolean "change_noted"
    t.integer "account_delivery_id"
  end

  create_table "customer_delivery_messages", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "delivery_id"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin_notified"
  end

  create_table "customer_delivery_requests", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "deliveries", id: :serial, force: :cascade do |t|
    t.integer "account_id"
    t.date "delivery_date"
    t.decimal "subtotal", precision: 6, scale: 2
    t.decimal "sales_tax", precision: 6, scale: 2
    t.decimal "total_drink_price", precision: 6, scale: 2
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "admin_delivery_review_note"
    t.text "admin_delivery_confirmation_note"
    t.boolean "delivery_change_confirmation"
    t.boolean "customer_has_previous_packaging"
    t.text "final_delivery_notes"
    t.boolean "share_admin_prep_with_user"
    t.boolean "recipient_is_21_plus"
    t.datetime "delivered_at"
    t.integer "order_prep_id"
    t.decimal "delivery_fee", precision: 5, scale: 2
    t.decimal "grand_total", precision: 5, scale: 2
    t.datetime "delivery_start_time"
    t.datetime "delivery_end_time"
    t.integer "account_address_id"
    t.boolean "has_customer_additions"
    t.decimal "delivery_credit", precision: 5, scale: 2
    t.index ["order_prep_id"], name: "index_deliveries_on_order_prep_id"
  end

  create_table "delivery_drivers", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "delivery_preferences", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.text "additional"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "gluten_free"
    t.text "admin_comments"
    t.integer "drinks_per_delivery"
    t.boolean "beer_chosen"
    t.boolean "cider_chosen"
    t.boolean "wine_chosen"
    t.integer "settings_complete"
    t.boolean "settings_confirmed"
    t.decimal "total_price_estimate", precision: 6, scale: 2
    t.boolean "delivery_frequency_chosen"
    t.boolean "delivery_time_window_chosen"
  end

  create_table "delivery_zones", id: :serial, force: :cascade do |t|
    t.string "zip_code"
    t.string "day_of_week"
    t.time "start_time"
    t.time "end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "weeks_of_year"
    t.integer "max_account_number"
    t.integer "current_account_number"
    t.datetime "beginning_at"
    t.integer "delivery_driver_id"
    t.decimal "excise_tax", precision: 8, scale: 6
    t.boolean "currently_available"
    t.integer "subscription_level_group"
  end

  create_table "disti_change_temps", id: :serial, force: :cascade do |t|
    t.integer "disti_item_number"
    t.string "maker_name"
    t.integer "maker_knird_id"
    t.string "drink_name"
    t.string "format"
    t.integer "size_format_id"
    t.decimal "drink_cost"
    t.decimal "drink_price_four_five"
    t.integer "distributor_id"
    t.string "disti_upc"
    t.integer "min_quantity"
    t.decimal "regular_case_cost"
    t.decimal "current_case_cost"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "drink_price_five_zero", precision: 5, scale: 2
    t.decimal "drink_price_five_five", precision: 5, scale: 2
  end

  create_table "disti_import_temps", id: :serial, force: :cascade do |t|
    t.integer "disti_item_number"
    t.string "maker_name"
    t.integer "maker_knird_id"
    t.string "drink_name"
    t.string "format"
    t.integer "size_format_id"
    t.decimal "drink_cost"
    t.decimal "drink_price_four_five"
    t.integer "distributor_id"
    t.string "disti_upc"
    t.integer "min_quantity"
    t.decimal "regular_case_cost"
    t.decimal "current_case_cost"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "drink_price_five_zero", precision: 5, scale: 2
    t.decimal "drink_price_five_five", precision: 5, scale: 2
  end

  create_table "disti_inventories", id: :serial, force: :cascade do |t|
    t.integer "beer_id"
    t.integer "size_format_id"
    t.decimal "drink_cost", precision: 5, scale: 2
    t.decimal "drink_price_four_five", precision: 5, scale: 2
    t.integer "distributor_id"
    t.integer "disti_item_number"
    t.string "disti_upc"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "min_quantity"
    t.decimal "regular_case_cost", precision: 5, scale: 2
    t.decimal "current_case_cost", precision: 5, scale: 2
    t.boolean "currently_available"
    t.boolean "curation_ready"
    t.decimal "drink_price_five_zero", precision: 5, scale: 2
    t.decimal "drink_price_five_five", precision: 5, scale: 2
    t.boolean "rate_for_users"
  end

  create_table "disti_orders", id: :serial, force: :cascade do |t|
    t.integer "distributor_id"
    t.integer "inventory_id"
    t.integer "case_quantity_ordered"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "distributors", id: :serial, force: :cascade do |t|
    t.string "disti_name"
    t.string "contact_name"
    t.string "contact_email"
    t.string "contact_phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "draft_boards", id: :serial, force: :cascade do |t|
    t.integer "location_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "draft_details", id: :serial, force: :cascade do |t|
    t.integer "drink_size"
    t.decimal "drink_cost", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "beer_location_id"
  end

  create_table "drink_options", id: :serial, force: :cascade do |t|
    t.string "drink_option_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "drink_style_top_descriptors", force: :cascade do |t|
    t.integer "beer_style_id"
    t.string "descriptor_name"
    t.integer "descriptor_tally"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tag_id"
  end

  create_table "free_curation_accounts", id: :serial, force: :cascade do |t|
    t.integer "account_id"
    t.integer "beer_id"
    t.integer "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "cellar"
    t.boolean "large_format"
    t.integer "free_curation_id"
    t.decimal "drink_price", precision: 5, scale: 2
    t.integer "size_format_id"
  end

  create_table "free_curation_users", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "free_curation_account_id"
    t.integer "free_curation_id"
    t.float "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "new_drink"
    t.string "likes_style"
    t.float "projected_rating"
    t.string "drink_category"
    t.boolean "user_reviewed"
  end

  create_table "free_curations", force: :cascade do |t|
    t.integer "account_id"
    t.date "requested_date"
    t.decimal "subtotal", precision: 6, scale: 2
    t.decimal "sales_tax", precision: 6, scale: 2
    t.decimal "total_price", precision: 6, scale: 2
    t.string "status"
    t.text "admin_curation_note"
    t.boolean "share_admin_prep"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "emails_sent"
    t.datetime "viewed_at"
    t.datetime "shared_at"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "friends", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "friend_id"
    t.boolean "confirmed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "mate"
  end

  create_table "gift_certificate_promotions", force: :cascade do |t|
    t.bigint "gift_certificate_id"
    t.integer "promotion_gift_certificate_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gift_certificate_id"], name: "index_gift_certificate_promotions_on_gift_certificate_id"
  end

  create_table "gift_certificates", id: :serial, force: :cascade do |t|
    t.string "giver_name"
    t.string "giver_email"
    t.string "receiver_email"
    t.decimal "amount"
    t.string "redeem_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "receiver_name"
    t.boolean "purchase_completed"
    t.boolean "redeemed"
    t.bigint "visit_id"
  end

  create_table "inventories", id: :serial, force: :cascade do |t|
    t.integer "beer_id"
    t.integer "stock"
    t.integer "reserved"
    t.integer "order_request"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "size_format_id"
    t.decimal "drink_price_four_five", precision: 5, scale: 2
    t.decimal "drink_cost", precision: 5, scale: 2
    t.integer "limit_per"
    t.integer "total_batch"
    t.boolean "currently_available"
    t.integer "distributor_id"
    t.integer "min_quantity"
    t.decimal "regular_case_cost", precision: 5, scale: 2
    t.decimal "sale_case_cost", precision: 5, scale: 2
    t.integer "disti_inventory_id"
    t.integer "total_demand"
    t.decimal "drink_price_five_zero", precision: 5, scale: 2
    t.decimal "drink_price_five_five", precision: 5, scale: 2
    t.date "packaged_on"
    t.date "best_by"
    t.string "drink_category"
    t.boolean "show_current_inventory"
    t.integer "comped"
    t.integer "shrinkage"
    t.boolean "membership_only"
    t.integer "nonmember_limit"
  end

  create_table "inventory_transactions", id: :serial, force: :cascade do |t|
    t.integer "account_delivery_id"
    t.integer "inventory_id"
    t.integer "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invitation_requests", id: :serial, force: :cascade do |t|
    t.string "email"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "zip_code"
    t.string "city"
    t.string "state"
    t.boolean "delivery_ok"
    t.datetime "birthday"
  end

  create_table "locations", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "homepage", limit: 255
    t.string "beerpage", limit: 255
    t.datetime "last_scanned"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "image_url"
    t.string "short_name"
    t.string "neighborhood"
    t.string "logo_small"
    t.string "logo_med"
    t.string "logo_large"
    t.boolean "ignore_location"
    t.string "facebook_url"
    t.string "twitter_url"
    t.string "address"
    t.string "phone_number"
    t.string "email"
    t.string "hours_one"
    t.string "hours_two"
    t.string "hours_three"
    t.string "hours_four"
    t.string "logo_holder"
    t.string "image_holder"
  end

  create_table "order_drink_preps", force: :cascade do |t|
    t.integer "user_id"
    t.integer "account_id"
    t.integer "inventory_id"
    t.integer "order_prep_id"
    t.integer "quantity"
    t.decimal "drink_price", precision: 6, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "order_preps", force: :cascade do |t|
    t.integer "account_id"
    t.decimal "subtotal", precision: 6, scale: 2
    t.decimal "sales_tax", precision: 6, scale: 2
    t.decimal "total_drink_price", precision: 6, scale: 2
    t.string "status"
    t.decimal "delivery_fee", precision: 6, scale: 2
    t.decimal "grand_total", precision: 6, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "delivery_zone_id"
    t.integer "start_time_option"
    t.integer "reserved_delivery_time_option_id"
    t.datetime "delivery_start_time"
    t.datetime "delivery_end_time"
  end

  create_table "pending_credits", id: :serial, force: :cascade do |t|
    t.float "transaction_credit"
    t.string "transaction_type"
    t.boolean "is_credited"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "credited_at"
    t.integer "delivery_id"
    t.integer "beer_id"
    t.integer "user_id"
    t.index ["account_id"], name: "index_pending_credits_on_account_id"
    t.index ["beer_id"], name: "index_pending_credits_on_beer_id"
    t.index ["delivery_id"], name: "index_pending_credits_on_delivery_id"
    t.index ["user_id"], name: "index_pending_credits_on_user_id"
  end

  create_table "pg_search_documents", id: :serial, force: :cascade do |t|
    t.text "content"
    t.integer "searchable_id"
    t.string "searchable_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable_type_and_searchable_id"
  end

  create_table "priorities", force: :cascade do |t|
    t.string "description"
    t.boolean "beer_relevant"
    t.boolean "cider_relevant"
    t.boolean "wine_relevant"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "projected_ratings", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "beer_id"
    t.float "projected_rating"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "inventory_id"
    t.integer "disti_inventory_id"
    t.boolean "user_rated"
  end

  create_table "removed_beer_locations", id: :serial, force: :cascade do |t|
    t.integer "beer_id"
    t.integer "location_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "removed_at"
  end

  create_table "reserved_delivery_time_options", force: :cascade do |t|
    t.integer "max_customers"
    t.integer "delivery_driver_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "start_time"
    t.datetime "end_time"
  end

  create_table "reward_points", id: :serial, force: :cascade do |t|
    t.integer "account_id"
    t.float "total_points"
    t.float "transaction_points"
    t.integer "reward_transaction_type_id"
    t.integer "account_delivery_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "friend_user_id"
    t.decimal "transaction_amount"
  end

  create_table "reward_transaction_types", id: :serial, force: :cascade do |t|
    t.string "reward_title"
    t.string "reward_description"
    t.string "reward_impact"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "reward_amount"
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.string "role_name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "shipments", id: :serial, force: :cascade do |t|
    t.integer "delivery_id"
    t.string "shipping_company"
    t.date "actual_shipping_date"
    t.date "estimated_arrival_date"
    t.string "tracking_number"
    t.decimal "estimated_shipping_fee", precision: 5, scale: 2
    t.decimal "actual_shipping_fee", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shipping_zones", id: :serial, force: :cascade do |t|
    t.integer "zone_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "excise_tax", precision: 8, scale: 6
    t.string "zip_start"
    t.string "zip_end"
    t.integer "subscription_level_group"
    t.boolean "currently_available"
  end

  create_table "shortened_urls", force: :cascade do |t|
    t.text "original_url"
    t.string "short_url"
    t.string "sanitize_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "size_formats", id: :serial, force: :cascade do |t|
    t.string "format_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "image"
    t.boolean "packaged"
    t.string "format_type"
  end

  create_table "special_codes", id: :serial, force: :cascade do |t|
    t.string "special_code"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "subscriptions", id: :serial, force: :cascade do |t|
    t.string "subscription_level"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "subscription_cost", precision: 5, scale: 2
    t.string "subscription_name"
    t.integer "subscription_months_length"
    t.decimal "extra_delivery_cost", precision: 5, scale: 2
    t.integer "deliveries_included"
    t.string "pricing_model"
    t.decimal "shipping_estimate_low", precision: 5, scale: 2
    t.decimal "shipping_estimate_high", precision: 5, scale: 2
    t.integer "subscription_level_group"
  end

  create_table "supply_types", id: :serial, force: :cascade do |t|
    t.string "designation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.integer "tag_id"
    t.integer "taggable_id"
    t.string "taggable_type"
    t.integer "tagger_id"
    t.string "tagger_type"
    t.string "context", limit: 128
    t.datetime "created_at"
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "temp_beer_brewery_collabs", id: :integer, default: -> { "nextval('beer_brewery_collabs_id_seq'::regclass)" }, force: :cascade do |t|
    t.integer "beer_id"
    t.integer "brewery_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "temp_beers", id: :integer, default: -> { "nextval('beers_id_seq'::regclass)" }, force: :cascade do |t|
    t.string "beer_name", limit: 255
    t.string "beer_type_old_name", limit: 255
    t.float "beer_rating_one"
    t.integer "number_ratings_one"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "brewery_id"
    t.float "beer_abv"
    t.integer "beer_ibu"
    t.string "beer_image", limit: 255
    t.string "speciality_notice", limit: 255
    t.text "original_descriptors"
    t.text "hops"
    t.text "grains"
    t.text "brewer_description"
    t.integer "beer_type_id"
    t.float "beer_rating_two"
    t.integer "number_ratings_two"
    t.float "beer_rating_three"
    t.integer "number_ratings_three"
    t.boolean "rating_one_na"
    t.boolean "rating_two_na"
    t.boolean "rating_three_na"
    t.boolean "user_addition"
    t.integer "touched_by_user"
    t.boolean "collab"
    t.string "short_beer_name"
    t.boolean "vetted"
    t.integer "touched_by_location"
    t.text "cellar_note"
  end

  create_table "temp_breweries", id: :integer, default: -> { "nextval('breweries_id_seq'::regclass)" }, force: :cascade do |t|
    t.string "brewery_name", limit: 255
    t.string "brewery_city", limit: 255
    t.string "brewery_state_short", limit: 255
    t.string "brewery_url", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "image"
    t.integer "brewery_beers"
    t.string "short_brewery_name"
    t.boolean "collab"
    t.boolean "vetted"
    t.string "brewery_state_long"
    t.string "facebook_url"
    t.string "twitter_url"
  end

  create_table "temp_breweries_temp_beers", id: :integer, default: -> { "nextval('beers_id_seq'::regclass)" }, force: :cascade do |t|
    t.string "beer_name", limit: 255
    t.string "beer_type_old_name", limit: 255
    t.float "beer_rating_one"
    t.integer "number_ratings_one"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "brewery_id"
    t.float "beer_abv"
    t.integer "beer_ibu"
    t.string "beer_image", limit: 255
    t.string "speciality_notice", limit: 255
    t.text "original_descriptors"
    t.text "hops"
    t.text "grains"
    t.text "brewer_description"
    t.integer "beer_type_id"
    t.float "beer_rating_two"
    t.integer "number_ratings_two"
    t.float "beer_rating_three"
    t.integer "number_ratings_three"
    t.boolean "rating_one_na"
    t.boolean "rating_two_na"
    t.boolean "rating_three_na"
    t.boolean "user_addition"
    t.integer "touched_by_user"
    t.boolean "collab"
    t.string "short_beer_name"
    t.boolean "vetted"
    t.integer "touched_by_location"
    t.text "cellar_note"
  end

  create_table "user_addresses", id: :serial, force: :cascade do |t|
    t.integer "account_id"
    t.string "address_street"
    t.string "address_unit"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.text "special_instructions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "location_type"
    t.string "other_name"
    t.boolean "current_delivery_location"
    t.integer "delivery_zone_id"
    t.integer "shipping_zone_id"
  end

  create_table "user_beer_ratings", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "beer_id"
    t.float "user_beer_rating"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "drank_at", limit: 255
    t.datetime "rated_on"
    t.float "projected_rating"
    t.text "comment"
    t.text "current_descriptors"
    t.integer "beer_type_id"
    t.integer "user_delivery_id"
  end

  create_table "user_cellar_supplies", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "beer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "total_quantity"
    t.integer "account_id"
    t.integer "remaining_quantity"
    t.integer "account_delivery_id"
  end

  create_table "user_deliveries", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "account_delivery_id"
    t.integer "delivery_id"
    t.float "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "new_drink"
    t.string "likes_style"
    t.float "projected_rating"
    t.integer "times_rated"
    t.string "drink_category"
    t.boolean "user_addition"
  end

  create_table "user_descriptor_preferences", force: :cascade do |t|
    t.integer "user_id"
    t.integer "beer_style_id"
    t.integer "tag_id"
    t.string "descriptor_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_drink_recommendations", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "beer_id"
    t.float "projected_rating"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "new_drink"
    t.integer "account_id"
    t.integer "size_format_id"
    t.integer "inventory_id"
    t.integer "disti_inventory_id"
    t.integer "number_of_ratings"
    t.date "delivered_recently"
    t.date "drank_recently"
  end

  create_table "user_fav_drinks", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "beer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "drink_rank"
  end

  create_table "user_locations", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "location_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "owner"
  end

  create_table "user_notification_preferences", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "notification_one"
    t.boolean "preference_one"
    t.float "threshold_one"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "notification_two"
    t.boolean "preference_two"
    t.float "threshold_two"
  end

  create_table "user_preference_beers", force: :cascade do |t|
    t.integer "user_id"
    t.integer "delivery_preference_id"
    t.decimal "beers_per_week", precision: 4, scale: 2
    t.integer "beers_per_delivery"
    t.decimal "beer_price_estimate", precision: 5, scale: 2
    t.integer "max_large_format"
    t.integer "max_cellar"
    t.boolean "gluten_free"
    t.text "additional"
    t.text "admin_comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "journey_stage"
    t.string "beer_price_response"
    t.decimal "beer_price_limit", precision: 5, scale: 2
  end

  create_table "user_preference_ciders", force: :cascade do |t|
    t.integer "user_id"
    t.integer "delivery_preference_id"
    t.decimal "ciders_per_week", precision: 4, scale: 2
    t.integer "ciders_per_delivery"
    t.decimal "cider_price_estimate", precision: 5, scale: 2
    t.integer "max_large_format"
    t.integer "max_cellar"
    t.text "additional"
    t.text "admin_comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "journey_stage"
    t.string "cider_price_response"
    t.decimal "cider_price_limit", precision: 5, scale: 2
  end

  create_table "user_preference_wines", force: :cascade do |t|
    t.integer "user_id"
    t.integer "delivery_preference_id"
    t.decimal "glasses_per_week", precision: 4, scale: 2
    t.integer "glasses_per_delivery"
    t.decimal "wine_price_estimate", precision: 5, scale: 2
    t.integer "max_cellar"
    t.text "additional"
    t.text "admin_comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "journey_stage"
  end

  create_table "user_priorities", force: :cascade do |t|
    t.integer "user_id"
    t.integer "priority_id"
    t.integer "priority_rank"
    t.integer "total_priorities"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "category"
  end

  create_table "user_style_preferences", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "beer_style_id"
    t.string "user_preference"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_subscriptions", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "subscription_id"
    t.datetime "active_until"
    t.string "stripe_customer_number"
    t.string "stripe_subscription_number"
    t.boolean "current_trial"
    t.boolean "trial_ended"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "auto_renew_subscription_id"
    t.integer "deliveries_this_period"
    t.integer "total_deliveries"
    t.integer "account_id"
    t.integer "renewals"
    t.boolean "currently_active"
    t.datetime "membership_join_date"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", limit: 255, default: "", null: false
    t.string "encrypted_password", limit: 255, default: ""
    t.string "reset_password_token", limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "role_id"
    t.string "username"
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.integer "invited_by_id"
    t.string "invited_by_type"
    t.integer "invitations_count", default: 0
    t.string "first_name"
    t.integer "craft_stage_id"
    t.string "last_name"
    t.integer "getting_started_step"
    t.string "cohort"
    t.date "birthday"
    t.string "user_graphic"
    t.string "user_color"
    t.string "special_code"
    t.string "tpw"
    t.integer "account_id"
    t.string "phone"
    t.boolean "recent_addition"
    t.string "homepage_view"
    t.boolean "unregistered"
    t.boolean "projected_ratings_complete"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_users_on_invitations_count"
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "wishlists", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "beer_id"
    t.datetime "removed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id"
  end

  create_table "zip_codes", id: :serial, force: :cascade do |t|
    t.string "zip_code"
    t.boolean "covered"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "city"
    t.string "state"
    t.string "homepage_view"
    t.string "geo_zip"
  end

  add_foreign_key "coupon_rules", "coupons"
  add_foreign_key "credits", "accounts"
  add_foreign_key "curation_requests", "accounts"
  add_foreign_key "curation_requests", "users"
  add_foreign_key "gift_certificate_promotions", "gift_certificates"
  add_foreign_key "pending_credits", "accounts"
  add_foreign_key "pending_credits", "beers"
  add_foreign_key "pending_credits", "deliveries"
  add_foreign_key "pending_credits", "users"
end
