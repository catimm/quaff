class AddMasterStyleIdToBeerStyle < ActiveRecord::Migration[5.1]
  def change
    add_column :beer_styles, :master_style_id, :integer
  end
end
