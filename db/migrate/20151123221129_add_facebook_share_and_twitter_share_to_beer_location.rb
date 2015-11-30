class AddFacebookShareAndTwitterShareToBeerLocation < ActiveRecord::Migration
  def change
    add_column :beer_locations, :facebook_share, :datetime
    add_column :beer_locations, :twitter_share, :datetime
  end
end
