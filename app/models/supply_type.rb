# == Schema Information
#
# Table name: supply_types
#
#  id          :integer          not null, primary key
#  designation :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class SupplyType < ActiveRecord::Base
  has_many :user_supplies
end
