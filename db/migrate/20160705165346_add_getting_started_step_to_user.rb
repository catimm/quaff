class AddGettingStartedStepToUser < ActiveRecord::Migration
  def change
    add_column :users, :getting_started_step, :integer
  end
end
