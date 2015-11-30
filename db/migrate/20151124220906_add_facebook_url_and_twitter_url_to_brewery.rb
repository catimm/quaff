class AddFacebookUrlAndTwitterUrlToBrewery < ActiveRecord::Migration
  def change
    add_column :breweries, :facebook_url, :string
    add_column :breweries, :twitter_url, :string
  end
end
