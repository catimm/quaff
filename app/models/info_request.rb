# == Schema Information
#
# Table name: info_requests
#
#  id         :integer          not null, primary key
#  email      :string
#  status     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  name       :string
#

class InfoRequest < ActiveRecord::Base
end
