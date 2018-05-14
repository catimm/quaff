class AddUnregisteredToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :unregistered, :boolean
  end
end
