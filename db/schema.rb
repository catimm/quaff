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

ActiveRecord::Schema.define(version: 20150426023042) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "beer_locations", force: true do |t|
    t.integer  "beer_id"
    t.integer  "location_id"
    t.string   "beer_is_current"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "removed_at"
  end

  create_table "beers", force: true do |t|
    t.string   "beer_name"
    t.string   "beer_type"
    t.decimal  "beer_rating"
    t.integer  "number_ratings"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "brewery_id"
    t.float    "beer_abv"
    t.integer  "beer_ibu"
    t.string   "beer_image"
    t.string   "tag_one"
    t.text     "descriptors"
  end

  create_table "breweries", force: true do |t|
    t.string   "brewery_name"
    t.string   "brewery_city"
    t.string   "brewery_state"
    t.string   "brewery_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "alt_name_one"
    t.string   "alt_name_two"
    t.string   "alt_name_three"
  end

  create_table "drink_lists", force: true do |t|
    t.integer  "user_id"
    t.integer  "beer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "locations", force: true do |t|
    t.string   "name"
    t.string   "homepage"
    t.string   "beerpage"
    t.datetime "last_scanned"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", force: true do |t|
    t.string   "role"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_beer_ratings", force: true do |t|
    t.integer  "user_id"
    t.integer  "beer_id"
    t.decimal  "user_beer_rating"
    t.string   "beer_descriptors"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "drank_at"
    t.datetime "rated_on"
  end

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
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
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
