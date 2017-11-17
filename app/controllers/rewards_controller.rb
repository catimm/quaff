class RewardsController < ApplicationController
  before_filter :authenticate_user!

  def index
    # get user info
    @user = User.find_by_id(current_user.id)
    # get account owner info
    @account_owner = User.where(account_id: @user.account_id, role_id: [1,4])[0]
    # get user rewards info
    @user_rewards = RewardPoint.where(account_id: @user.account_id).sort_by(&:updated_at).reverse
    
    # get user subscription info
    @user_subscription = UserSubscription.where(user_id: @account_owner.id, currently_active: true)[0]
    if @user_subscription.subscription_id == 3
      @reward_multiplier_text = "1.5 bottle caps"
      @reward_multiplier = 1.5
    else
      @reward_multiplier_text = "1 bottle cap"
      @reward_multiplier = 1
    end
    
    # find if user has purchased drinks in the last month but not rated them
    @unrated_drinks = AccountDelivery.where(account_id: @user.account_id).where("quantity > times_rated").where('created_at >= ?', 1.month.ago)
    #Rails.logger.debug("Unrated drinks: #{@unrated_drinks.inspect}")
    @total_possible_to_rate = @unrated_drinks.sum(:quantity)
    #Rails.logger.debug("Total possible drinks: #{@total_possible_to_rate.inspect}")
    @total_rated = @unrated_drinks.sum(:times_rated)
    @number_of_unrated_drinks = @total_possible_to_rate - @total_rated
    #Rails.logger.debug("# of Unrated drinks: #{@number_of_unrated_drinks.inspect}")
    # get total value of unrated drinks
    @total_reward_opportunity = 0
    @unrated_drinks.each do |drink|
      @number_unrated = drink.quantity - drink.times_rated
      @rewards_value = @number_unrated * drink.drink_price * @reward_multiplier
      @total_reward_opportunity = @total_reward_opportunity + @rewards_value
    end
    
  end #end of index method
    
end