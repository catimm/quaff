# == Schema Information
#
# Table name: special_package_drinks
#
#  id                 :integer          not null, primary key
#  special_package_id :integer
#  inventory_id       :integer
#  quantity           :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

class SpecialPackageDrink < ApplicationRecord
  belongs_to :special_package
  belongs_to :inventory
end
