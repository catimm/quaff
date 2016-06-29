class AddStandardListToBeerStyle < ActiveRecord::Migration
  def change
    add_column :beer_styles, :standard_list, :boolean
  end
end
