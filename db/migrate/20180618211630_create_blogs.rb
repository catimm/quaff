class CreateBlogs < ActiveRecord::Migration[5.1]
  def change
    create_table :blogs do |t|
      t.string :title
      t.string :subtitle
      t.string :status
      t.text :content
      t.string :image_url
      t.integer :user_id
      t.datetime :published_at

      t.timestamps
    end
  end
end
