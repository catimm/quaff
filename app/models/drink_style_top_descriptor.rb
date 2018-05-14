# == Schema Information
#
# Table name: drink_style_top_descriptors
#
#  id               :integer          not null, primary key
#  beer_style_id    :integer
#  descriptor_name  :string
#  descriptor_tally :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  tag_id           :integer
#

class DrinkStyleTopDescriptor < ApplicationRecord
  belongs_to :beer_style

end
