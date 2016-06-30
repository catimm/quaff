# == Schema Information
#
# Table name: beer_styles
#
#  id                :integer          not null, primary key
#  style_name        :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  style_image_url   :string
#  signup_beer       :boolean
#  signup_cider      :boolean
#  signup_beer_cider :boolean
#  standard_list     :boolean
#  style_order       :integer
#

require 'test_helper'

class BeerStyleTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
