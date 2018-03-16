class AddHomepageViewToUser < ActiveRecord::Migration
  def change
    add_column :users, :homepage_view, :string
  end
end
