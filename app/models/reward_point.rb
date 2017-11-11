# == Schema Information
#
# Table name: reward_points
#
#  id                         :integer          not null, primary key
#  account_id                 :integer
#  total_points               :float
#  transaction_points         :float
#  reward_transaction_type_id :integer
#  account_delivery_id        :integer
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  friend_user_id             :integer
#

class RewardPoint < ActiveRecord::Base
  belongs_to :account 
  belongs_to :beer
  belongs_to :reward_transaction_type
end
