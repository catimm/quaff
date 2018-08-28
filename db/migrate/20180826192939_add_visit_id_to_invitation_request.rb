class AddVisitIdToInvitationRequest < ActiveRecord::Migration[5.1]
  def change
    add_column :invitation_requests, :visit_id, :bigint
  end
end
