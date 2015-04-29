# == Schema Information
#
# Table name: alt_brewery_names
#
#  id         :integer          not null, primary key
#  name       :string
#  brewery_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class AltBreweryName < ActiveRecord::Base
end
