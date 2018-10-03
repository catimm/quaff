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

require 'test_helper'

class SpecialPackageDrinkTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
