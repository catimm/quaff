class CreateRewardTransactionTypes < ActiveRecord::Migration
  def change
    create_table :reward_transaction_types do |t|
      t.string :reward_title
      t.string :reward_description
      t.string :reward_impact

      t.timestamps null: false
    end
  end
end
