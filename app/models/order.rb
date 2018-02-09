# == Schema Information
#
# Table name: orders
#
#  id                     :integer          not null, primary key
#  account_id             :integer
#  drink_type             :string
#  number_of_drinks       :integer
#  number_of_large_drinks :integer
#  delivery_date          :datetime
#  additional_requests    :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  drink_option_id        :integer
#  user_id                :integer
#

class Order < ActiveRecord::Base
  belongs_to :account
  validates :delivery_date, presence: { message: 'Please select a date for your delivery.'}
  validates :number_of_drinks, presence: { message: 'Please select the number of drinks you would like to order.'}
  validates :number_of_large_drinks, presence: { message: 'Please select the max large format drinks you would like to include in your order.'}
  validates :additional_requests,  length: { maximum: 500, too_long: "%{count} characters is the maximum allowed for additional requests." }, allow_blank: true
end
