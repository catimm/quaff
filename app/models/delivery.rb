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
#

class Delivery < ActiveRecord::Base
  belongs_to :account
  
  has_many :account_deliveries
  has_many :admin_account_deliveries
  has_many :user_deliveries    
  has_many :admin_user_deliveries
  has_many :customer_delivery_messages
  has_many :customer_delivery_changes
  
  attr_accessor :delivery_quantity # hold number of drinks to be in the delivery
  
  # create view in admin recommendation drop down
  def recommendation_drop_down_view
    #Rails.logger.debug("This account: #{account.id.inspect}")
    @account_owner = User.where(account_id: account.id, role_id: [1,4])[0]
    #Rails.logger.debug("account owner info: #{@account_owner.inspect}")
    "#{delivery_date.strftime("%m/%d/%y")}: #{@account_owner.first_name} [#{@account_owner.username}]"
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
