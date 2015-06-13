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

ActiveRecord::Schema.define(version: 20150612190732) do

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

  create_table "beer_locations", force: :cascade do |t|
    t.integer  "beer_id"
    t.integer  "location_id"
    t.string   "beer_is_current"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "removed_at"
  end

  create_table "beer_styles", force: :cascade do |t|
    t.string   "style_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.integer  "beer_style_id"
    t.string   "beer_type_short_name"
  end

  create_table "beers", force: :cascade do |t|
    t.string   "beer_name"
    t.string   "beer_type_old_name"
    t.float    "beer_rating_one"
    t.integer  "number_ratings_one"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "brewery_id"
    t.float    "beer_abv"
    t.integer  "beer_ibu"
    t.string   "beer_image"
    t.string   "speciality_notice"
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
  end

  create_table "breweries", force: :cascade do |t|
    t.string   "brewery_name"
    t.string   "brewery_city"
    t.string   "brewery_state"
    t.string   "brewery_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "image"
    t.integer  "brewery_beers"
    t.string   "short_brewery_name"
    t.boolean  "collab"
  end

  create_table "drink_lists", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "beer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "location_trackings", force: :cascade do |t|
    t.integer  "user_beer_tracking_id"
    t.integer  "location_id"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  create_table "locations", force: :cascade do |t|
    t.string   "name"
    t.string   "homepage"
    t.string   "beerpage"
    t.datetime "last_scanned"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "image_url"
    t.string   "short_name"
    t.string   "neighborhood"
    t.string   "logo_small"
    t.string   "logo_med"
    t.string   "logo_large"
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
    t.string   "role_name"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.string   "drank_at"
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

  create_table "user_style_preferences", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "beer_style_id"
    t.string   "user_preference"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: ""
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
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
    t.integer  "invitations_count",      default: 0
    t.string   "first_name"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["invitation_token"], name: "index_users_on_invitation_token", unique: true, using: :btree
  add_index "users", ["invitations_count"], name: "index_users_on_invitations_count", using: :btree
  add_index "users", ["invited_by_id"], name: "index_users_on_invited_by_id", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
