class ActivitiesController < ApplicationController
  before_filter :authenticate_user!, :except => [:stripe_webhooks]
  include DrinkTypeDescriptorCloud
  include DrinkDescriptorCloud
  include DrinkDescriptors
  include CreateNewDrink
  include DeliveryEstimator
  include BestGuess
  include QuerySearch
  require "stripe"
  require 'json'
  
  def user_ratings
    # get user info
    @user = User.find(params[:id])
    
    # get user ratings history
    @user_ratings = UserBeerRating.where(user_id: params[:id])
    
    # get recent user ratings history
    @recent_user_ratings = @user_ratings.order(created_at: :desc).paginate(:page => params[:page], :per_page => 12)
  
  end # end of user_ratings method 
  
  def friend_ratings
    # get user info
    @user = User.find(params[:id])
    
    # find user's friends
    @user_friends = Friend.where(confirmed: true).where("user_id = :this_user_id OR friend_id = :this_user_id", this_user_id: params[:id])
          .pluck(:user_id, :friend_id).uniq.compact - [params[:id]]
    
    # get friends ratings history
    @friend_ratings = UserBeerRating.where(user_id: @user_friends)
    
    # get recent user ratings history
    @recent_friend_ratings = @friend_ratings.order(created_at: :desc).paginate(:page => params[:page], :per_page => 12)
    
  end # end of friend_ratings method
  
  private
  
  
end