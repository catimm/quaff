class CreatePendingCredits < ActiveRecord::Migration
  def change
    create_table :pending_credits do |t|
      t.float :transaction_credit
      t.string :transaction_type
      t.boolean :is_credited
      t.references :account, index: true

      t.timestamps null: false
    end
    add_foreign_key :pending_credits, :accounts
  end
end
