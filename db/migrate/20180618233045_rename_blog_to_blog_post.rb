class RenameBlogToBlogPost < ActiveRecord::Migration[5.1]
  def change
    rename_table :blogs, :blog_posts
  end
end
