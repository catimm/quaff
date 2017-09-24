class CreateProjectedRatings < ActiveRecord::Migration
  def change
    create_table :projected_ratings do |t|
      t.integer :user_id
      t.integer :beer_id
      t.float :projected_rating

      t.timestamps null: false
    end
  end
end
