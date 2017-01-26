# == Schema Information
#
# Table name: discount_codes
#
#  id            :integer          not null, primary key
#  discount_code :string
#  user_id       :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class DiscountCode < ActiveRecord::Base
  belongs_to :user
end
