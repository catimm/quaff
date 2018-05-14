# == Schema Information
#
# Table name: user_priorities
#
#  id               :integer          not null, primary key
#  user_id          :integer
#  priority_id      :integer
#  priority_rank    :integer
#  total_priorities :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  category         :string
#

class UserPriority < ApplicationRecord
  belongs_to :user
  belongs_to :priority
end
