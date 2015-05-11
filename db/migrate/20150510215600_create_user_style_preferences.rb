class CreateUserStylePreferences < ActiveRecord::Migration
  def change
    create_table :user_style_preferences do |t|
      t.integer :user_id
      t.integer :beer_style_id
      t.string :user_preference

      t.timestamps null: false
    end
  end
end
