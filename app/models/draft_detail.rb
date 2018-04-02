# == Schema Information
# Provides drink size and drink cost information for each drink on tap at a retailer
# Table name: draft_details
#
#  id               :integer          not null, primary key
#  drink_size       :integer
#  drink_cost       :decimal(5, 2)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  beer_location_id :integer
#

class DraftDetail < ApplicationRecord
  belongs_to :beer_location
end
