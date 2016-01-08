class CreateInfoRequests < ActiveRecord::Migration
  def change
    create_table :info_requests do |t|
      t.string :email
      t.string :status

      t.timestamps null: false
    end
  end
end
