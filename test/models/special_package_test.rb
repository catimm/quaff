# == Schema Information
#
# Table name: special_packages
#
#  id            :integer          not null, primary key
#  title         :string
#  retail_cost   :decimal(5, 2)
#  actual_cost   :decimal(5, 2)
#  quantity      :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  package_image :string
#  review_title  :string
#

require 'test_helper'

class SpecialPackageTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
