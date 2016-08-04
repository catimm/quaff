class AddBirthdayToInvitationRequest < ActiveRecord::Migration
  def change
    add_column :invitation_requests, :birthday, :datetime
  end
end
