# == Schema Information
#
# Table name: special_codes
#
#  id           :integer          not null, primary key
#  special_code :string
#  user_id      :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class SpecialCode < ApplicationRecord
  belongs_to :user
end
