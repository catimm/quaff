# == Schema Information
#
# Table name: reward_transaction_types
#
#  id                 :integer          not null, primary key
#  reward_title       :string
#  reward_description :string
#  reward_impact      :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  reward_amount      :integer
#

class RewardTransactionType < ApplicationRecord
  has_many :reward_points 
end
