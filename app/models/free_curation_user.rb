# == Schema Information
#
# Table name: free_curation_users
#
#  id                       :integer          not null, primary key
#  user_id                  :integer
#  free_curation_account_id :integer
#  free_curation_id         :integer
#  quantity                 :float
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  new_drink                :boolean
#  likes_style              :string
#  projected_rating         :float
#  drink_category           :string
#  user_reviewed            :boolean
#

class FreeCurationUser < ApplicationRecord
  belongs_to :user
  belongs_to :free_curation_account
  belongs_to :free_curation

end
