# == Schema Information
#
# Table name: admin_user_deliveries
#
#  id                       :integer          not null, primary key
#  user_id                  :integer
#  beer_id                  :integer
#  inventory_id             :integer
#  new_drink                :boolean
#  projected_rating         :float
#  likes_style              :string
#  quantity                 :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  cellar                   :boolean
#  large_format             :boolean
#  delivery_id              :integer
#  this_beer_descriptors    :text
#  beer_style_name_one      :string
#  beer_style_name_two      :string
#  recommendation_rationale :string
#  is_hybrid                :boolean
#

require 'test_helper'

class AdminUserDeliveryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
