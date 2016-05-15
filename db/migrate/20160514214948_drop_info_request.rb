class DropInfoRequest < ActiveRecord::Migration
  def change
    drop_table :info_requests
  end
end
