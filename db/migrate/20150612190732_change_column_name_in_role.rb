class ChangeColumnNameInRole < ActiveRecord::Migration
  def change
    rename_column :roles, :role, :role_name
  end
end
