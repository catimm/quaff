# == Schema Information
#
# Table name: alt_beer_names
#
#  id         :integer          not null, primary key
#  name       :string
#  beer_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class AltBeerName < ApplicationRecord
  belongs_to :beer
end
