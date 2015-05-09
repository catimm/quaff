class CreateBeerTypeRelationships < ActiveRecord::Migration
  def change
    create_table :beer_type_relationships do |t|
      t.integer :beer_type_id
      t.integer :relationship_one
      t.integer :relationship_two
      t.integer :relationship_three
      t.text :rationale

      t.timestamps null: false
    end
  end
end
