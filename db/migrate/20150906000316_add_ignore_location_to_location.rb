class AddIgnoreLocationToLocation < ActiveRecord::Migration
  def change
    add_column :locations, :ignore_location, :boolean
  end
end
