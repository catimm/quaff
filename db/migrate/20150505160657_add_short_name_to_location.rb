class AddShortNameToLocation < ActiveRecord::Migration
  def change
    add_column :locations, :short_name, :string
  end
end
