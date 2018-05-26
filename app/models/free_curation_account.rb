# == Schema Information
#
# Table name: free_curation_accounts
#
#  id               :integer          not null, primary key
#  account_id       :integer
#  beer_id          :integer
#  quantity         :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  cellar           :boolean
#  large_format     :boolean
#  free_curation_id :integer
#  drink_price      :decimal(5, 2)
#  size_format_id   :integer
#

class FreeCurationAccount < ApplicationRecord
  belongs_to :account
  belongs_to :beer
  belongs_to :free_curation   
  belongs_to :size_format, optional: true
  
  has_many :free_curation_users
  
  attr_accessor :top_descriptor_list # to hold list of top drink descriptors
  
end
