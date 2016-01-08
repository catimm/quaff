class AddNameToInfoRequest < ActiveRecord::Migration
  def change
    add_column :info_requests, :name, :string
  end
end
