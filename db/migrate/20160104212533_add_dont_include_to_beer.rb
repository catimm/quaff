class AddDontIncludeToBeer < ActiveRecord::Migration
  def change
    add_column :beers, :dont_include, :boolean
  end
end
