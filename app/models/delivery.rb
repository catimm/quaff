# == Schema Information
#
# Table name: deliveries
#
#  id                               :integer          not null, primary key
#  account_id                       :integer
#  delivery_date                    :date
#  subtotal                         :decimal(6, 2)
#  sales_tax                        :decimal(6, 2)
#  total_price                      :decimal(6, 2)
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
#  order_id                         :integer
#  no_plan_delivery_fee             :decimal(5, 2)
#  grand_total                      :decimal(5, 2)
#

class Delivery < ApplicationRecord
  belongs_to :account
  belongs_to :order, optional: true
  
  has_many :delivery_zones
  has_many :account_deliveries
  has_many :user_deliveries
  has_many :customer_delivery_messages
  has_many :customer_delivery_changes
  has_many :shipments, dependent: :destroy
  
  attr_accessor :delivery_quantity # hold number of drinks to be in the delivery
  
  # create view in admin recommendation drop down
  def recommendation_delivery_drop_down_view
    "#{self.delivery_date} [#{self.status}]"
  end
  
  # current accounts with upcoming deliveries
  def self.current_accounts_with_upcoming_deliveries
    @current_account_ids = UserSubscription.where(currently_active: true).pluck(:account_id)
    @account_ids = Delivery.where(account_id: @current_account_ids, delivery_date: (Date.today)..(13.days.from_now)).pluck(:account_id)
  end
  
  # scope account owners
  scope :account_owner, -> {
    joins(:account).merge(Account.owner)
  }
  # scope not yet delivered
  scope :not_yet_delivered, -> {
    where.not(status: "delivered").order('delivery_date ASC')
  }
  
  # scope already delivered
  scope :already_delivered, -> {
    where(status: "delivered").order('delivery_date DESC')
  }
  
  # scope drink counts in this delivery
  def delivery_drink_count
    self.account_deliveries.sum(:quantity)
  end
  
  # scope small drink count in this delivery
  def delivery_small_count
    self.account_deliveries.
    where(:large_format => false ).
    sum(:quantity)
  end
  
  # scope large drink count in this delivery
  def delivery_large_count
    self.account_deliveries.
    where(:large_format => true ).
    sum(:quantity)
  end
  
  # scope cellar drink count in this delivery
  def delivery_cellar_count
    self.account_deliveries.
    where(:cellar => true ).
    sum(:quantity)
  end
end
