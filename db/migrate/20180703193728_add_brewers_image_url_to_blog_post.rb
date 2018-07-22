class AddBrewersImageUrlToBlogPost < ActiveRecord::Migration[5.1]
  def change
    add_column :blog_posts, :brewers_image_url, :string
  end
end
