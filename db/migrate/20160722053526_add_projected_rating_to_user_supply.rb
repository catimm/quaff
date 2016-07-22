class AddProjectedRatingToUserSupply < ActiveRecord::Migration
  def change
    add_column :user_supplies, :projected_rating, :float
  end
end
