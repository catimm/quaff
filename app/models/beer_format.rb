# == Schema Information
#
# Table name: beer_formats
#
#  id             :integer          not null, primary key
#  beer_id        :integer
#  size_format_id :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class BeerFormat < ActiveRecord::Base
  belongs_to :beer
  belongs_to :size_format

end
