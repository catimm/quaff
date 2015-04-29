# == Schema Information
#
# Table name: breweries
#
#  id            :integer          not null, primary key
#  brewery_name  :string
#  brewery_city  :string
#  brewery_state :string
#  brewery_url   :string
#  created_at    :datetime
#  updated_at    :datetime
#

class Brewery < ActiveRecord::Base
  has_many :beers

end
