# == Schema Information
#
# Table name: user_supplies
#
#  id             :integer          not null, primary key
#  user_id        :integer
#  beer_id        :integer
#  supply_type_id :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  quantity       :integer
#

class UserSupply < ActiveRecord::Base
  belongs_to :user
  belongs_to :beer
  belongs_to :supply_type
end
