# == Schema Information
#
# Table name: user_cellar_supplies
#
#  id                   :integer          not null, primary key
#  user_id              :integer
#  beer_id              :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  quantity             :integer
#  projected_rating     :float
#  purchased_from_knird :boolean
#  account_id           :integer
#

class UserCellarSupply < ActiveRecord::Base
  belongs_to :user
  belongs_to :account
  belongs_to :beer
  belongs_to :supply_type
end
