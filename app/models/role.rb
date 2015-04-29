# == Schema Information
#
# Table name: roles
#
#  id         :integer          not null, primary key
#  role       :string
#  created_at :datetime
#  updated_at :datetime
#

class Role < ActiveRecord::Base
  has_many :users
end
