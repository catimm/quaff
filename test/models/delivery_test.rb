# == Schema Information
#
# Table name: deliveries
#
#  id                               :integer          not null, primary key
#  account_id                       :integer
#  delivery_date                    :date
#  subtotal                         :decimal(6, 2)
#  sales_tax                        :decimal(6, 2)
#  total_drink_price                :decimal(6, 2)
#  status                           :string
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  admin_delivery_review_note       :text
#  admin_delivery_confirmation_note :text
#  delivery_change_confirmation     :boolean
#  customer_has_previous_packaging  :boolean
#  final_delivery_notes             :text
#  share_admin_prep_with_user       :boolean
#  recipient_is_21_plus             :boolean
#  delivered_at                     :datetime
#  order_prep_id                    :integer
#  no_plan_delivery_fee             :decimal(5, 2)
#  grand_total                      :decimal(5, 2)
#  delivery_start_time              :datetime
#  delivery_end_time                :datetime
#  account_address_id               :integer
#

require 'test_helper'

class DeliveryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
