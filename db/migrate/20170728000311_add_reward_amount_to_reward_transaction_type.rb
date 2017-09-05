class AddRewardAmountToRewardTransactionType < ActiveRecord::Migration
  def change
    add_column :reward_transaction_types, :reward_amount, :integer
  end
end
