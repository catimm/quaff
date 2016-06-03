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
  # :confirmable, :lockable, :timeoutable and :registerable
  devise :invitable, :database_authenticatable, :omniauthable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauth_providers => [:facebook, :twitter]
  
  # for ActsAsTaggableOn gem
  acts_as_tagger
  
  belongs_to :role       
  has_many :user_beer_ratings
  has_many :beers, through: :user_beer_ratings
  has_many :wishlists
  has_many :user_notification_preferences
  has_many :user_style_preferences
  has_many :user_locations
  has_many :user_drink_recommendations
  has_many :user_fav_drinks
  has_many :user_supplies
  has_many :user_next_deliveries
  
  attr_accessor :top_type_descriptor_list # to hold list of top drink descriptors
  
  # set user roles for cancancan
  def super_admin?
    self.role.role_name == "super_admin"
  end
  
  def admin?
    self.role.role_name == "admin"
  end
  
  def super_retailer?
    self.role.role_name == "super_retailer"
  end
  
  def retailer?
    self.role.role_name == "retailer"
  end
  
  def retailer_test?
    self.role.role_name == "retailer_test"
  end
  
  def super_user?
    self.role.role_name == "super_user"
  end
  
  def user?
    self.role.role_name == "user"
  end
  
  def free?
    self.subscription.subscription_level == "free"
  end
  
  def retain?
    self.subscription.subscription_level == "retain"
  end
  
  # get recepient emails for Mandrill
  def self.mandrill_emails(users)
   users.map{|user| {:email => user.email}}
  end
  
  # connect recepient names to emails for Mandrill
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
