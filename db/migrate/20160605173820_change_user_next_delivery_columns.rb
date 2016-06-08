class ChangeUserNextDeliveryColumns < ActiveRecord::Migration
  def change
    rename_table :user_next_deliveries, :user_deliveries
    remove_column :user_deliveries, :user_drink_recommendation_id, :integer
    remove_column :user_deliveries, :cooler, :boolean
    remove_column :user_deliveries, :small_format, :boolean
    add_column :user_deliveries, :beer_id, :integer
    add_column :user_deliveries, :projected_rating, :float
    add_column :user_deliveries, :style_preference, :string
    add_column :user_deliveries, :quantity, :integer
    add_column :user_deliveries, :delivered, :datetime
  end
end
