class CreateUserPreferenceWines < ActiveRecord::Migration[5.1]
  def change
    create_table :user_preference_wines do |t|
      t.integer :user_id
      t.integer :delivery_preference_id
      t.integer :glasses_per_week
      t.integer :glasses_per_delivery
      t.decimal :wine_price_estimate, :precision => 5, :scale => 2
      t.integer :max_cellar
      t.text :additional
      t.text :admin_comments
      
      t.timestamps null: false
    end
  end
end
