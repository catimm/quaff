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

ActiveRecord::Schema.define(version: 20151202064358) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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

  create_table "beer_locations", force: :cascade do |t|
    t.integer  "beer_id"
    t.integer  "location_id"
    t.string   "beer_is_current",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "removed_at"
    t.integer  "tap_number"
    t.integer  "draft_board_id"
    t.float    "keg_size"
    t.datetime "went_live"
    t.boolean  "special_designation"
    t.string   "special_designation_color"
    t.boolean  "show_up_next"
    t.datetime "facebook_share"
    t.datetime "twitter_share"
  end

  create_table "beer_styles", force: :cascade do |t|
    t.string   "style_name"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "style_image_url"
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
    t.boolean  "dont_include"
    t.string   "brewery_state_long"
    t.string   "facebook_url"
    t.string   "twitter_url"
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

  create_table "drink_lists", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "beer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "internal_draft_board_preferences", force: :cascade do |t|
    t.integer  "draft_board_id"
    t.boolean  "separate_names"
    t.boolean  "column_names"
    t.integer  "font_size"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  create_table "invitation_requests", force: :cascade do |t|
    t.string   "email"
    t.string   "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "location_subscriptions", force: :cascade do |t|
    t.integer  "location_id"
    t.integer  "subscription_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  create_table "location_trackings", force: :cascade do |t|
    t.integer  "user_beer_tracking_id"
    t.integer  "location_id"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
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
  end

  create_table "pg_search_documents", force: :cascade do |t|
    t.text     "content"
    t.integer  "searchable_id"
    t.string   "searchable_type"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "pg_search_documents", ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable_type_and_searchable_id", using: :btree

  create_table "roles", force: :cascade do |t|
    t.string   "role_name",  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.string   "subscription_level"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
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
  end

  create_table "user_beer_trackings", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "beer_id"
    t.datetime "removed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_locations", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "location_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
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
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["invitation_token"], name: "index_users_on_invitation_token", unique: true, using: :btree
  add_index "users", ["invitations_count"], name: "index_users_on_invitations_count", using: :btree
  add_index "users", ["invited_by_id"], name: "index_users_on_invited_by_id", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
