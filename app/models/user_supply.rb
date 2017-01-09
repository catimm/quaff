# == Schema Information
#
# Table name: user_supplies
#
#  id                       :integer          not null, primary key
#  user_id                  :integer
#  beer_id                  :integer
#  supply_type_id           :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  quantity                 :integer
#  cellar_note              :text
#  projected_rating         :float
#  this_beer_descriptors    :text
#  beer_style_name_one      :string
#  beer_style_name_two      :string
#  recommendation_rationale :string
#  is_hybrid                :boolean
#  likes_style              :string
#  admin_vetted             :boolean
#

class UserSupply < ActiveRecord::Base
  belongs_to :user
  belongs_to :beer
  belongs_to :supply_type
end
