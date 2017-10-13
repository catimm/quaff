class CreateDistributors < ActiveRecord::Migration
  def change
    create_table :distributors do |t|
      t.string :disti_name
      t.string :contact_name
      t.string :contact_email
      t.string :contact_phone

      t.timestamps null: false
    end
  end
end
