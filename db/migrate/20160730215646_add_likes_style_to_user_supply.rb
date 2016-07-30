class AddLikesStyleToUserSupply < ActiveRecord::Migration
  def change
    add_column :user_supplies, :likes_style, :string
  end
end
