class CreateRewardPoints < ActiveRecord::Migration
  def change
    create_table :reward_points do |t|
      t.integer :user_id
      t.float :total_points
      t.float :transaction_points
      t.integer :reward_transaction_type_id
      t.integer :beer_id

      t.timestamps null: false
    end
  end
end
