class RenameColumnInShortenedUrl < ActiveRecord::Migration[5.1]
  def change
    rename_column :shortened_urls, :orginal_url, :original_url
  end
end
