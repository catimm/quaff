class AddBeerIdAndUntappdUrlAndBaUrlToBlog < ActiveRecord::Migration[5.1]
  def change
    add_column :blogs, :beer_id, :integer
    add_column :blogs, :untappd_url, :string
    add_column :blogs, :ba_url, :string
  end
end
