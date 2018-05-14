class AddBeerChosenAndCiderChosenAndWineChosenToDeliveryPreference < ActiveRecord::Migration[5.1]
  def change
    add_column :delivery_preferences, :beer_chosen, :boolean
    add_column :delivery_preferences, :cider_chosen, :boolean
    add_column :delivery_preferences, :wine_chosen, :boolean
  end
end
