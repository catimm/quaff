class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.string :account_type
      t.integer :number_of_users

      t.timestamps null: false
    end
  end
end
