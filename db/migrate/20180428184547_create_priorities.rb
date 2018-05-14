class CreatePriorities < ActiveRecord::Migration[5.1]
  def change
    create_table :priorities do |t|
      t.string :description
      t.boolean :beer_relevant
      t.boolean :cider_relevant
      t.boolean :wine_relevant

      t.timestamps
    end
  end
end
