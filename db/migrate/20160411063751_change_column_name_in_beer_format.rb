class ChangeColumnNameInBeerFormat < ActiveRecord::Migration
  def change
    rename_column :beer_formats, :format_id, :size_format_id
  end
end
