class MakeChangesToOrderModel < ActiveRecord::Migration[5.1]
  def change
    rename_column :orders, :number_of_drinks, :number_of_beers
    add_column :orders, :number_of_ciders, :integer
    add_column :orders, :number_of_glasses, :integer
  end
end
