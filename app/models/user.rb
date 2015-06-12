# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default("")
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default("0"), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  created_at             :datetime
#  updated_at             :datetime
#  role_id                :integer
#  username               :string
#  invitation_token       :string
#  invitation_created_at  :datetime
#  invitation_sent_at     :datetime
#  invitation_accepted_at :datetime
#  invitation_limit       :integer
#  invited_by_id          :integer
#  invited_by_type        :string
#  invitations_count      :integer          default("0")
#  first_name             :string
#

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable, :registerable
  devise :invitable, :database_authenticatable, 
         :recoverable, :rememberable, :trackable, :validatable
  
  # for ActsAsTaggableOn gem
  acts_as_tagger
  
  belongs_to :role       
  has_many :user_beer_ratings
  has_many :beers, through: :user_beer_ratings
  has_many :drink_lists
  has_many :beers, through: :drink_lists
  has_many :user_beer_trackings
  
  def super_admin?
    self.role.role == "super_admin"
  end
  
  def admin?
    self.role.role == "admin"
  end
  
  def super_user?
    self.role.role == "super_user"
  end
  
  def user?
    self.role.role == "user"
  end
end
