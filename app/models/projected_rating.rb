# == Schema Information
#
# Table name: projected_ratings
#
#  id                 :integer          not null, primary key
#  user_id            :integer
#  beer_id            :integer
#  projected_rating   :float
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  inventory_id       :integer
#  disti_inventory_id :integer
#  user_rated         :boolean
#

class ProjectedRating < ApplicationRecord
  belongs_to :user
  belongs_to :beer
  belongs_to :inventory, optional: true
  belongs_to :disti_inventory, optional: true
  
  attr_accessor :top_descriptor_list # to hold list of top drink descriptors
  
end
