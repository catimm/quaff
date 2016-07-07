class AddBetaTesterToUser < ActiveRecord::Migration
  def change
    add_column :users, :beta_tester, :boolean
  end
end
