class RemoveSpecialDesignationAndSpecialDesignationColorFromDraftDetail < ActiveRecord::Migration
  def change
    remove_column :draft_details, :special_designation, :boolean
    remove_column :draft_details, :special_designation_color, :string
  end
end
