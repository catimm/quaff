class AddDrinkOptionIdToOrder < ActiveRecord::Migration
  def change
    add_column :orders, :drink_option_id, :integer
  end
end
