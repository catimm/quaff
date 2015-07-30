# == Schema Information
#
# Table name: invitation_requests
#
#  id         :integer          not null, primary key
#  email      :string
#  status     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class InvitationRequest < ActiveRecord::Base
end
