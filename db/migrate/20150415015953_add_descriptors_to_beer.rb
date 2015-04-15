class AddDescriptorsToBeer < ActiveRecord::Migration
  def change
    add_column :beers, :descriptors, :text
  end
end
