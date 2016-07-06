class AddMaxCellarToDeliveryPreference < ActiveRecord::Migration
  def change
    add_column :delivery_preferences, :max_cellar, :integer
  end
end
