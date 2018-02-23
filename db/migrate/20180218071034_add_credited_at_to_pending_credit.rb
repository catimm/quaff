class AddCreditedAtToPendingCredit < ActiveRecord::Migration
  def change
    add_column :pending_credits, :credited_at, :datetime
  end
end
