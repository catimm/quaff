class AddKnirdLiveTrialToAccount < ActiveRecord::Migration[5.1]
  def change
    add_column :accounts, :knird_live_trial, :boolean
  end
end
