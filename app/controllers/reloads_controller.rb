class ReloadsController < ApplicationController
  before_filter :verify_admin
    include UserLikesDrinkTypes
    include TypeBasedGuess
    include BestGuess
    
  def index
    # get user info
    @early_user = User.find_by_id(14)
    # get user subscription info
    @early_user_subscription = UserSubscription.find_by_user_id(@early_user.id)
    if @early_user_subscription.subscription_id == 1
      @user_subscription = "1-month"
      @bottle_caps = "40"
      @number_of_drinks = "one free drink"
    elsif @early_user_subscription.subscription_id == 2
      @user_subscription = "3-month"
      @bottle_caps = "250"
      @number_of_drinks = "six free drinks"
    else
      @user_subscription = "12-month"
      @bottle_caps = "250"
      @number_of_drinks = "six free drinks"
    end
    # get user's invitation code
    @user_invitation_code = SpecialCode.where(user_id: @early_user.id).first
    
    # send early signup follow-up email
    UserMailer.early_signup_followup(@early_user, @user_subscription, @user_invitation_code.special_code).deliver_now

    # award reward points to @early_user for signup up early
    RewardPoint.create(user_id: @early_user.id, total_points: @bottle_caps, transaction_points: @bottle_caps,
                        reward_transaction_type_id: 6) 

      
  end # end index action
  
  private
  
  def verify_admin
      redirect_to root_url unless current_user.role_id == 1
    end
    
end