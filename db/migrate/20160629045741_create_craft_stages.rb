class CreateCraftStages < ActiveRecord::Migration
  def change
    create_table :craft_stages do |t|
      t.string :stage_name

      t.timestamps null: false
    end
  end
end
