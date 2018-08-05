# == Schema Information
#
# Table name: beer_type_relationships
#
#  id                 :integer          not null, primary key
#  beer_type_id       :integer
#  relationship_one   :integer
#  relationship_two   :integer
#  relationship_three :integer
#  rationale          :text
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

class BeerTypeRelationship < ApplicationRecord
  belongs_to :beer_types
  
  # scope related drink styles based on first relationship
  scope :related_drink_type_one, ->(style_id) {
    where(relationship_one: style_id).pluck(:beer_type_id)
  }
  
  # scope related drink styles based on second relationship
  scope :related_drink_type_two, ->(style_id) {
    where(relationship_two: style_id).pluck(:beer_type_id)
  }
  
end
