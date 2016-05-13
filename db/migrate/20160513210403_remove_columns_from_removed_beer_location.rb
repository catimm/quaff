class RemoveColumnsFromRemovedBeerLocation < ActiveRecord::Migration
  def change
    remove_column :removed_beer_locations, :beer_is_current
    remove_column :removed_beer_locations, :keg_size
    remove_column :removed_beer_locations, :went_live
    remove_column :removed_beer_locations, :special_designation
    remove_column :removed_beer_locations, :special_designation_color
    remove_column :removed_beer_locations, :facebook_share
    remove_column :removed_beer_locations, :twitter_share
    remove_column :removed_beer_locations, :price_tier_id
    remove_column :removed_beer_locations, :drink_category_id
    remove_column :removed_beer_locations, :tap_number
    remove_column :removed_beer_locations, :draft_board_id
  end
end
