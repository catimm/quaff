# == Schema Information
#
# Table name: drink_lists
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  beer_id    :integer
#  created_at :datetime
#  updated_at :datetime
#

class DrinkList < ActiveRecord::Base
end
