class RemoveAdminVettedFromUserCellarSupply < ActiveRecord::Migration
  def change
    remove_column :user_cellar_supplies, :admin_vetted, :boolean
  end
end
