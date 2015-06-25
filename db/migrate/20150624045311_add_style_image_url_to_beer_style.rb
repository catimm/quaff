class AddStyleImageUrlToBeerStyle < ActiveRecord::Migration
  def change
    add_column :beer_styles, :style_image_url, :string
  end
end
