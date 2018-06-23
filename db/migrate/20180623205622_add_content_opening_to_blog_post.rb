class AddContentOpeningToBlogPost < ActiveRecord::Migration[5.1]
  def change
    add_column :blog_posts, :content_opening, :text
  end
end
