# == Schema Information
#
# Table name: account_deliveries
#
#  id                     :integer          not null, primary key
#  account_id             :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  beer_id                :integer
#  quantity               :integer
#  delivery_id            :integer
#  cellar                 :boolean
#  large_format           :boolean
#  drink_price            :decimal(5, 2)
#  times_rated            :integer
#  moved_to_cellar_supply :boolean
#  size_format_id         :integer
#  inventory_id           :integer
#  special_package_id     :integer
#

class AccountDelivery < ApplicationRecord
  belongs_to :account
  belongs_to :beer, optional: true
  belongs_to :delivery
  belongs_to :size_format
  belongs_to :inventory
  belongs_to :special_package, optional: true
  
  has_many :user_deliveries
  
  attr_accessor :beer_rating  # to hold user drink rating or projected rating
  attr_accessor :this_beer_descriptors # to hold list of descriptors user typically likes/dislikes
  attr_accessor :top_descriptor_list # to hold list of top drink descriptors
  
  # determine whether drink has been delivered within last month
  scope :delivered_recently, ->(user_id, account_id, drink_id) {
    where(id: account_id, beer_id: drink_id).
    joins(:user_deliveries).
    where('user_deliveries.user_id = ?', user_id).
    joins(:delivery).
    where('deliveries.status = ?', "delivered").
    where('deliveries.delivery_date > ?', 1.month.ago)
  } # end of within_last scope
  
  # method for inventory limits
  def inventory_limit
    @this_inventory = self.inventory_transactions.joins(:inventory).in_stock
    if @this_inventory.limit_per.nil? && self.inventory.stock > 0
      return true
    else
      if self.inventory_transactions.inventory.stock > 0 
        if self.quantity < self.inventory_transactions.inventory.limit_per
          return true
        else
          return false
        end
      else
        return false
      end
    end
  end # end of method
  
end
