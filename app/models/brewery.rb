# == Schema Information
#
# Table name: breweries
#
#  id             :integer          not null, primary key
#  brewery_name   :string(255)
#  brewery_city   :string(255)
#  brewery_state  :string(255)
#  brewery_url    :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#  alt_name_one   :string(255)
#  alt_name_two   :string(255)
#  alt_name_three :string(255)
#

class Brewery < ActiveRecord::Base
  has_many :beers

end
