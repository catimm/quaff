# == Schema Information
#
# Table name: accounts
#
#  id                                :integer          not null, primary key
#  account_type                      :string
#  number_of_users                   :integer
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#  delivery_location_user_address_id :integer
#  delivery_zone_id                  :integer
#

class Account < ActiveRecord::Base
  has_many :account_deliveries
  has_many :admin_account_deliveries
  has_many :deliveries
  has_many :user_subscriptions
  has_many :user_addresses
  accepts_nested_attributes_for :user_addresses, :allow_destroy => true
  has_many :users
  accepts_nested_attributes_for :users, :allow_destroy => true
  
  attr_accessor :user_id # to hold current user id
    
  # create view in admin recommendation drop down
  def recommendation_account_drop_down_view
    @account_owner = User.where(account_id: self.id, role_id: [1,4])[0]
    Rails.logger.debug("Acct owner: #{@account_owner.inspect}")
    @next_delivery = Delivery.where(account_id: self.id).where.not(status: "delivered").order("delivery_date ASC").first
    Rails.logger.debug("Next delivery: #{@next_delivery.inspect}")
    "#{@account_owner.first_name} [#{@account_owner.username} next on #{@next_delivery.delivery_date}]"
  end
  
  # scope not yet delivered to account owners
  scope :not_delivered_owner, -> {
    joins(:users).merge(User.account_owner).
    joins(:deliveries).merge(Delivery.not_yet_delivered) 
  }
  
  # scope delivered to account owners
  scope :delivered_owner, -> {
    joins(:users).merge(User.account_owner).
    joins(:deliveries).merge(Delivery.already_delivered)
  }
  
end
