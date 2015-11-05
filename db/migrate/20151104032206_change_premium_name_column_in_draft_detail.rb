class ChangePremiumNameColumnInDraftDetail < ActiveRecord::Migration
  def change
    rename_column :draft_details, :premium_drink, :special_designation
    add_column :draft_details, :special_designation_color, :string
  end
end
