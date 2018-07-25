# == Schema Information
#
# Table name: shortened_urls
#
#  id           :integer          not null, primary key
#  original_url :text
#  short_url    :string
#  sanitize_url :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require 'test_helper'

class ShortenedUrlTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
