# == Schema Information
#
# Table name: temp_breweries
#
#  id                  :integer          not null, primary key
#  brewery_name        :string(255)
#  brewery_city        :string(255)
#  brewery_state_short :string(255)
#  brewery_url         :string(255)
#  created_at          :datetime
#  updated_at          :datetime
#  image               :string
#  brewery_beers       :integer
#  short_brewery_name  :string
#  collab              :boolean
#  vetted              :boolean
#  brewery_state_long  :string
#  facebook_url        :string
#  twitter_url         :string
#

class TempBrewery < ActiveRecord::Base

  
end
