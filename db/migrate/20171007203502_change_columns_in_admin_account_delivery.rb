class ChangeColumnsInAdminAccountDelivery < ActiveRecord::Migration
  def change
    remove_column :admin_account_deliveries, :drink_cost, :decimal, :precision => 5, :scale => 2
    remove_column :admin_account_deliveries, :this_beer_descriptors, :text
    remove_column :admin_account_deliveries, :beer_style_name_one, :string
    remove_column :admin_account_deliveries, :beer_style_name_two, :string
    remove_column :admin_account_deliveries, :recommendation_rationale, :string
    remove_column :admin_account_deliveries, :is_hybrid, :boolean
    remove_column :admin_account_deliveries, :new_drink, :boolean
    remove_column :admin_account_deliveries, :likes_style, :string
  end
end