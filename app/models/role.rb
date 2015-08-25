# == Schema Information
#
# Table name: roles
#
#  id         :integer          not null, primary key
#  role_name  :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class Role < ActiveRecord::Base
  has_many :users
end
