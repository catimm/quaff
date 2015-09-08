class AddDraftBoardIdToBeerLocation < ActiveRecord::Migration
  def change
    add_column :beer_locations, :draft_board_id, :integer
  end
end
