class AddWeeksOfYearToDeliveryZone < ActiveRecord::Migration
  def change
    add_column :delivery_zones, :weeks_of_year, :string
  end
end
