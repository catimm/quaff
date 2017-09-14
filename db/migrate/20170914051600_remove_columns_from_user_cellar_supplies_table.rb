class RemoveColumnsFromUserCellarSuppliesTable < ActiveRecord::Migration
  def change
    remove_column :user_cellar_supplies, :supply_type_id, :integer
    remove_column :user_cellar_supplies, :this_beer_descriptors, :text
    remove_column :user_cellar_supplies, :beer_style_name_one, :string
    remove_column :user_cellar_supplies, :beer_style_name_two, :string
    remove_column :user_cellar_supplies, :recommendation_rationale, :string
    remove_column :user_cellar_supplies, :is_hybrid, :boolean
    remove_column :user_cellar_supplies, :likes_style, :string
    remove_column :user_cellar_supplies, :cellar_note, :text
                  
  end
end
