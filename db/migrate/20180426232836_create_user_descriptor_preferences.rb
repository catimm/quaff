class CreateUserDescriptorPreferences < ActiveRecord::Migration[5.1]
  def change
    create_table :user_descriptor_preferences do |t|
      t.integer :user_id
      t.integer :beer_style_id
      t.integer :tag_id
      t.string :descriptor_name

      t.timestamps
    end
  end
end
