# == Schema Information
#
# Table name: authentications
#
#  id           :integer          not null, primary key
#  user_id      :integer
#  provider     :string
#  uid          :string
#  token        :string
#  token_secret :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  location_id  :integer
#

class Authentication < ActiveRecord::Base
  belongs_to :user
end
