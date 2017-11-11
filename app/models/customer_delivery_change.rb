# == Schema Information
#
# Table name: customer_delivery_changes
#
#  id                  :integer          not null, primary key
#  user_id             :integer
#  delivery_id         :integer
#  user_delivery_id    :integer
#  original_quantity   :integer
#  new_quantity        :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  beer_id             :integer
#  change_noted        :boolean
#  account_delivery_id :integer
#

class CustomerDeliveryChange < ActiveRecord::Base
  belongs_to :user
  belongs_to :delivery
  belongs_to :account_delivery
  belongs_to :user_delivery
  belongs_to :beer
end
