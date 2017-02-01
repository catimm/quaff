class ChangeBetaTesterInUserToCohort < ActiveRecord::Migration
  def change
    rename_column :users, :beta_tester, :cohort
    change_column :users, :cohort, :string
  end
end
