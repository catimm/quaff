class CreateInvitationRequests < ActiveRecord::Migration
  def change
    create_table :invitation_requests do |t|
      t.string :email
      t.string :status

      t.timestamps null: false
    end
  end
end
