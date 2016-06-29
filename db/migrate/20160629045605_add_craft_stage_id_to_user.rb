class AddCraftStageIdToUser < ActiveRecord::Migration
  def change
    add_column :users, :craft_stage_id, :integer
  end
end
