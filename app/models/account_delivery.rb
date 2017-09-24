# == Schema Information
#
# Table name: account_deliveries
#
#  id                       :integer          not null, primary key
#  account_id               :integer
#  inventory_id             :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  beer_id                  :integer
#  quantity                 :integer
#  delivery_id              :integer
#  cellar                   :boolean
#  large_format             :boolean
#  drink_cost               :decimal(5, 2)
#  drink_price              :decimal(5, 2)
#  this_beer_descriptors    :text
#  beer_style_name_one      :string
#  beer_style_name_two      :string
#  recommendation_rationale :string
#  is_hybrid                :boolean
#  times_rated              :integer
#  moved_to_cellar_supply   :boolean
#

class AccountDelivery < ActiveRecord::Base
  belongs_to :user
  belongs_to :inventory
  belongs_to :beer
  belongs_to :delivery
  
  has_many :user_deliveries    

  attr_accessor :beer_rating  # to hold user drink rating or projected rating
  attr_accessor :this_beer_descriptors # to hold list of descriptors user typically likes/dislikes
  attr_accessor :top_descriptor_list # to hold list of top drink descriptors
  
  # determine whether drink has been delivered within last 6 weeks
  scope :delivered_recently, ->(user_id, drink_id) {
    where(user_id: user_id, beer_id: drink_id).
    joins(:delivery).
    where('deliveries.status = ?', "delivered")
    #where('deliveries.delivery_date > ?', 6.weeks.ago)
  } # end of within_last scope
  
  # method for inventory limits
  def inventory_limit
    if self.inventory.limit_per.nil? && self.inventory.stock > 0
      return true
    else
      if self.inventory.stock > 0 
        if self.quantity < self.inventory.limit_per
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
