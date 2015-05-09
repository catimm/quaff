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

class BeerTypeRelationship < ActiveRecord::Base
  belongs_to :beer_types
end
