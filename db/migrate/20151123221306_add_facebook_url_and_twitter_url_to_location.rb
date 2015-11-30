class AddFacebookUrlAndTwitterUrlToLocation < ActiveRecord::Migration
  def change
    add_column :locations, :facebook_url, :string
    add_column :locations, :twitter_url, :string
  end
end
