class CreateShortenedUrls < ActiveRecord::Migration[5.1]
  def change
    create_table :shortened_urls do |t|
      t.text :orginal_url
      t.string :short_url
      t.string :sanitize_url
      t.timestamps
    end
  end
end
