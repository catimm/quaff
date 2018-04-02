# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default("")
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
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
#  invitations_count      :integer          default(0)
#  first_name             :string
#  craft_stage_id         :integer
#  last_name              :string
#  getting_started_step   :integer
#  cohort                 :string
#  birthday               :date
#  user_graphic           :string
#  user_color             :string
#  special_code           :string
#  tpw                    :string
#  account_id             :integer
#  phone                  :string
#  recent_addition        :boolean
#  homepage_view          :string
#

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :registerable
  devise :invitable, :database_authenticatable, :omniauthable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauth_providers => [:facebook, :twitter]
  
  validates_confirmation_of :password
  validates :password_confirmation, :presence =>true, on: :create # only on create so users can edit without needing to input a new password with confirmation
  validates_uniqueness_of :username, if: "!username.nil?"
  
  # add searchkick to find other users (friends)
  searchkick
  
  # for ActsAsTaggableOn gem
  acts_as_tagger
  
  belongs_to :role 
  belongs_to :account
  
  has_many :user_deliveries
  has_many :delivery_drivers    
  has_many :admin_user_deliveries   
  has_many :user_subscriptions
  has_many :user_beer_ratings
  has_many :friends
  has_many :beers, through: :user_beer_ratings
  has_many :wishlists
  has_many :user_notification_preferences
  has_many :user_style_preferences
  has_many :user_locations
  has_many :user_drink_recommendations
  has_many :user_fav_drinks
  has_many :user_supplies
  has_many :craft_stages
  has_many :reward_points
  has_many :projected_ratings
  has_many :customer_delivery_requests
  has_many :orders
  
  attr_accessor :top_type_descriptor_list # to hold list of top drink descriptors
  attr_accessor :valid_special_code # to hold special code
  attr_accessor :password_confirmation # to confirm password
  attr_accessor :specific_drink_best_guess # to hold temp drink best guess
  attr_accessor :account_name # to hold account name for corp signup process
  
  # set user roles for cancancan
  def super_admin?
    self.role.role_name == "super_admin"
  end
  
  def admin?
    self.role.role_name == "admin"
  end
  
  def super_user?
    self.role.role_name == "super_user"
  end
  
  def user?
    self.role.role_name == "user_owner"
  end
  
  def user?
    self.role.role_name == "user_guest"
  end
  
  def free?
    self.subscription.subscription_level == "free"
  end
  
  def retain?
    self.subscription.subscription_level == "retain"
  end
  
  # scope account owner
  scope :account_owner, -> {
    where(role_id: [1,4]) 
  }
  
  # create Instance Method for user drink rating
  def user_drink_rating(drink_id)
    @user_drink_rating = UserBeerRating.where(user_id: self.id, beer_id: drink_id)
    if !@user_drink_rating.blank?
      @user_average_rating = (@user_drink_rating.average(:user_beer_rating).to_f).round(1)
      if @user_average_rating >= 10.0
        @final_rating = 10
      else
        @final_rating = @user_average_rating
      end
    else
      @final_rating = nil
    end
    @final_rating
  end
  
  # create Instance Method for drink projected rating
  def user_drink_projected_rating(drink_id)
    @projected_rating = ProjectedRating.where(user_id: self.id, beer_id: drink_id)[0]
    if !@projected_rating.blank?
      if @projected_rating.projected_rating >= 10.0
        @final_projection = 10
      else
        @final_projection = @projected_rating.projected_rating
      end
    else
      @final_projection = nil
    end
    @final_projection
  end
  
  # create Instance Method for a user's friend
  def friend_status(friend_id)
    @friend_status = Friend.where("(user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)", self.id, friend_id, friend_id, self.id)[0]

    @friend_status
  end
  
  # create Class Method for recepient emails for Mandrill
  def self.mandrill_emails(users)
   users.map{|user| {:email => user.email}}
  end
  
  # create Class Method recepient names to emails for Mandrill
  def self.mandrill_names_and_emails(users)
    users.map{|user| {:rcpt => user.email, :vars => [{:name => 'first_name', :content => user.first_name}]}}
  end
  
  # to fix a devise error when trying to set new password
  def after_password_reset; end
  
  # for filterrific sorting of admin drink recommendation page
  def self.options_for_select
    order('LOWER(username)').map { |e| [e.username, e.id] }
  end

  
  #def apply_omniauth(omni)
  #  authentications.build(:provider => omni['provider'],
  #  :uid => omni['uid'],
  #  :token => omni['credentials']['token'],
  #  :token_secret => omni['credentials']['secret'])
  #end
  
  #def ensure_authentication_token
  #  if self.authentication_token.blank?
  #    new_token = ""
  #    loop do
  #      new_token = SecureRandom.base64(15).tr('+/=lIO0', 'pqrsxyz')
  #      # break token unless to_adapter.find_first({ :authentication_token => token })
  #      break unless User.where(:authentication_token => new_token).count > 0
  #    end
  #    self.authentication_token = new_token
  #  end
  #end

    
  # let devise know that a password isn't required if the user logs in through Facebook
  #def password_required?
  #  (authentications.empty? || !password.blank?) && super
  #end
  
  # tell devise to not show the password field for the edit settings page if user logs in through Facebook
  #def update_with_password(params, *options)
  #  if encrypted_password.blank?
  #    update_attributes(params, *options)
  #  else
  #    super
  #  end
  #end
  
end
