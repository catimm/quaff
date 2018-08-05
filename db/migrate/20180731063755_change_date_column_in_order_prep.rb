class ChangeDateColumnInOrderPrep < ActiveRecord::Migration[5.1]
  def change
    change_column :order_preps, :delivery_date, :date
  end
end
