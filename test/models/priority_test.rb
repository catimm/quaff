# == Schema Information
#
# Table name: priorities
#
#  id             :integer          not null, primary key
#  description    :string
#  beer_relevant  :boolean
#  cider_relevant :boolean
#  wine_relevant  :boolean
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

require 'test_helper'

class PriorityTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
