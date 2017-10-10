class ChangeColumnsInAccountDelivery < ActiveRecord::Migration
  def change
    remove_column :account_deliveries, :drink_cost, :decimal, :precision => 5, :scale => 2
    remove_column :account_deliveries, :this_beer_descriptors, :text
    remove_column :account_deliveries, :beer_style_name_one, :string
    remove_column :account_deliveries, :beer_style_name_two, :string
    remove_column :account_deliveries, :recommendation_rationale, :string
    remove_column :account_deliveries, :is_hybrid, :boolean
    remove_column :account_deliveries, :inventory_id, :integer
    add_column :account_deliveries, :size_format_id, :integer
  end
end
