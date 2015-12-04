class AddFieldsToLocationTable < ActiveRecord::Migration
  def change
    add_column :locations, :address, :string
    add_column :locations, :phone_number, :string
    add_column :locations, :email, :string
    add_column :locations, :hours_one, :string
    add_column :locations, :hours_two, :string
    add_column :locations, :hours_three, :string
    add_column :locations, :hours_four, :string 
  end
end
