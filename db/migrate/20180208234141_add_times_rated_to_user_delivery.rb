class AddTimesRatedToUserDelivery < ActiveRecord::Migration
  def change
    add_column :user_deliveries, :times_rated, :integer
  end
end
