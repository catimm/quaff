# == Schema Information
#
# Table name: craft_stages
#
#  id         :integer          not null, primary key
#  stage_name :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class CraftStage < ActiveRecord::Base
  belongs_to :user
end
