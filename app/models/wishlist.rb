# == Schema Information
#
# Table name: wishlists
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  beer_id    :integer
#  removed_at :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :integer
#

class Wishlist < ApplicationRecord
  belongs_to :user
  belongs_to :beer
  belongs_to :account

  
end
