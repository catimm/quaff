# == Schema Information
#
# Table name: breweries
#
#  id                 :integer          not null, primary key
#  brewery_name       :string
#  brewery_city       :string
#  brewery_state      :string
#  brewery_url        :string
#  created_at         :datetime
#  updated_at         :datetime
#  image              :string
#  brewery_beers      :integer
#  short_brewery_name :string
#

class Brewery < ActiveRecord::Base
  has_many :beers
  has_many :alt_brewery_names
  
  def connect_deleted_brewery
    "#{brewery_name} [id: #{id}]"
  end
end
