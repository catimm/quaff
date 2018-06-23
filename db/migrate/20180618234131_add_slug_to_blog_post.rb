class AddSlugToBlogPost < ActiveRecord::Migration[5.1]
  def change
    add_column :blog_posts, :slug, :string
  end
end
