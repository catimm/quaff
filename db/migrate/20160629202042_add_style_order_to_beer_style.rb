class AddStyleOrderToBeerStyle < ActiveRecord::Migration
  def change
    add_column :beer_styles, :style_order, :integer
  end
end
