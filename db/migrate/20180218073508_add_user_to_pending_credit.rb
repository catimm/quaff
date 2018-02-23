class AddUserToPendingCredit < ActiveRecord::Migration
  def change
    add_reference :pending_credits, :user, index: true
    add_foreign_key :pending_credits, :users
  end
end
