class AddTransactionAmountToRewardPoint < ActiveRecord::Migration
  def change
    add_column :reward_points, :transaction_amount, :decimal
  end
end
