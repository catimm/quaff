# == Schema Information
#
# Table name: blogs
#
#  id           :integer          not null, primary key
#  title        :string
#  subtitle     :string
#  status       :string
#  content      :text
#  image_url    :string
#  user_id      :integer
#  published_at :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  beer_id      :integer
#  untappd_url  :string
#  ba_url       :string
#

require 'test_helper'

class BlogTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
