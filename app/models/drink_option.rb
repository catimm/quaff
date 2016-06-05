# == Schema Information
#
# Table name: drink_options
#
#  id                :integer          not null, primary key
#  drink_option_name :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class DrinkOption < ActiveRecord::Base
  has_many :delivery_preferences
  
end
