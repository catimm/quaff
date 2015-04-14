# == Schema Information
#
# Table name: locations
#
#  id           :integer          not null, primary key
#  name         :string(255)
#  homepage     :string(255)
#  beerpage     :string(255)
#  last_scanned :datetime
#  created_at   :datetime
#  updated_at   :datetime
#

class Location < ActiveRecord::Base
  has_many :beer_locations
  has_many :beers, through: :beer_locations
  
  def self.options_for_select
    order('LOWER(name)').map { |e| [e.name, e.id] }
  end
end
