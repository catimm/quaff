class CreateZipCodes < ActiveRecord::Migration
  def change
    create_table :zip_codes do |t|
      t.string :zip_code
      t.boolean :covered

      t.timestamps null: false
    end
  end
end
