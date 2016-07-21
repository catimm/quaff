class AddCellarNoteToUserSupply < ActiveRecord::Migration
  def change
    add_column :user_supplies, :cellar_note, :text
  end
end
