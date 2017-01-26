class AddTpwToUser < ActiveRecord::Migration
  def change
    add_column :users, :tpw, :string
  end
end
