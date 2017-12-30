class CreateCredits < ActiveRecord::Migration
  def change
    create_table :credits do |t|
      t.float :total_credit
      t.float :transaction_credit
      t.string :transaction_type
      t.references :account, index: true

      t.timestamps null: false
    end
    add_foreign_key :credits, :accounts
  end
end
