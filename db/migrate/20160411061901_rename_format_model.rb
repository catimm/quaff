class RenameFormatModel < ActiveRecord::Migration
  def change
    rename_table :formats, :size_formats
  end
end
