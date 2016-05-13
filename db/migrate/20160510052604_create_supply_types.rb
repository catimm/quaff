class CreateSupplyTypes < ActiveRecord::Migration
  def change
    create_table :supply_types do |t|
      t.string :designation

      t.timestamps null: false
    end
  end
end
