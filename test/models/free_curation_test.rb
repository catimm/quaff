# == Schema Information
#
# Table name: free_curations
#
#  id                  :integer          not null, primary key
#  account_id          :integer
#  requested_date      :date
#  subtotal            :decimal(6, 2)
#  sales_tax           :decimal(6, 2)
#  total_price         :decimal(6, 2)
#  status              :string
#  admin_curation_note :text
#  share_admin_prep    :boolean
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  emails_sent         :integer
#  viewed_at           :datetime
#  shared_at           :datetime
#

require 'test_helper'

class FreeCurationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
