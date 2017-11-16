class AddRecentAdditionToUser < ActiveRecord::Migration
  def change
    add_column :users, :recent_addition, :boolean
  end
end
