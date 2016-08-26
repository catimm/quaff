class AddUserGraphicToUser < ActiveRecord::Migration
  def change
    add_column :users, :user_graphic, :string
  end
end
