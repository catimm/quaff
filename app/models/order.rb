# == Schema Information
#
# Table name: orders
#
#  id                     :integer          not null, primary key
#  account_id             :integer
#  drink_type             :string
#  number_of_beers        :integer
#  number_of_large_drinks :integer
#  delivery_date          :datetime
#  additional_requests    :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  drink_option_id        :integer
#  user_id                :integer
#  number_of_ciders       :integer
#  number_of_glasses      :integer
#

class Order < ApplicationRecord
  belongs_to :account
  has_many :deliveries
  validates :delivery_date, presence: { message: 'Please select a date for your delivery.'}
  validates :number_of_beers, presence: { message: 'Please select the number of beers you would like to order.'}
  validates :number_of_ciders, presence: { message: 'Please select the number of ciders you would like to order.'}
  validates :number_of_glasses, presence: { message: 'Please select the number of glasses of wine you would like to order.'}
  validates :additional_requests,  length: { maximum: 500, too_long: "%{count} characters is the maximum allowed for additional requests." }, allow_blank: true
end
