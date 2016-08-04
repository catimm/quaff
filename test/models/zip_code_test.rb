# == Schema Information
#
# Table name: zip_codes
#
#  id         :integer          not null, primary key
#  zip_code   :string
#  covered    :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  city       :string
#  state      :string
#

require 'test_helper'

class ZipCodeTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
