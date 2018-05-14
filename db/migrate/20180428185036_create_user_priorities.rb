class CreateUserPriorities < ActiveRecord::Migration[5.1]
  def change
    create_table :user_priorities do |t|
      t.integer :user_id
      t.integer :priority_id
      t.integer :priority_rank
      t.integer :total_priorities

      t.timestamps
    end
  end
end
