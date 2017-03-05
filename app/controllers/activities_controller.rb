class ActivitiesController < ApplicationController
  before_filter :authenticate_user!, :except => [:stripe_webhooks]
  include DrinkTypeDescriptorCloud
  include DrinkDescriptorCloud
  include DrinkDescriptors
  include CreateNewDrink
  include DeliveryEstimator
  include BestGuess
  include FriendSearch
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
          .pluck(:user_id, :friend_id).uniq.flatten(1) - [current_user.id]
    #Rails.logger.debug("User friends: #{@user_friends.inspect}")
    # get friends ratings history
    @friend_ratings = UserBeerRating.where(user_id: @user_friends)
    
    # get recent user ratings history
    @recent_friend_ratings = @friend_ratings.order(created_at: :desc).paginate(:page => params[:page], :per_page => 12)
    
  end # end of friend_ratings method
  
  def manage_friends
    # find user's friends
    @user_friend_ids = Friend.where(confirmed: true).where("user_id = :this_user_id OR friend_id = :this_user_id", this_user_id: params[:id])
          .pluck(:user_id, :friend_id).uniq.flatten(1) - [current_user.id]
    #Rails.logger.debug("User friends: #{@user_friends.inspect}")
    @user_friends = User.where(id: @user_friend_ids)
    
    # find pending friends
    @pending_friend_ids = Friend.where(confirmed: [false, nil]).where("user_id = :this_user_id OR friend_id = :this_user_id", this_user_id: params[:id])
          .pluck(:user_id, :friend_id).uniq.flatten(1) - [current_user.id]
    #Rails.logger.debug("Pending friends: #{@pending_friend_ids.inspect}")  
    @pending_friends = User.where(id: @pending_friend_ids)   
  end # end manage_friends method
  
  def process_friend_search
    # conduct search
    friend_search(params[:query])
    
    # hold current query in a session variable
    session[:current_query] = params[:query]
    
    # show results
     respond_to do |format|
      format.js
      format.html
    end # end of redirect to jquery
    
  end # end of process_friend_search method
  
  def process_friend_changes
    # get data to add/update
    @data = params[:id]
    @data_split = @data.split("-")
    @status = @data_split[0]
    @action = @data_split[1]
    @id = @data_split[2]
    
    # update friend table
    if @status == "invited"
      if @action == "drop"
        @friend_status = Friend.where("user_id = :this_user_id OR friend_id = :this_user_id", this_user_id: current_user.id).
                                where("user_id = :this_user_id OR friend_id = :this_user_id", this_user_id: @id)[0]
        @friend_status.destroy!
      else
        @friend_status = Friend.where("user_id = :this_user_id OR friend_id = :this_user_id", this_user_id: current_user.id).
                                where("user_id = :this_user_id OR friend_id = :this_user_id", this_user_id: @id)[0]
        @friend_status.update(confirmed: true)
      end
    else
      @new_friend_request = Friend.create(user_id: current_user.id, friend_id: @id)
    
    end
    
    # find user's friends
    @user_friend_ids = Friend.where(confirmed: true).where("user_id = :this_user_id OR friend_id = :this_user_id", this_user_id: current_user.id)
          .pluck(:user_id, :friend_id).uniq.flatten(1) - [current_user.id]
    #Rails.logger.debug("User friends: #{@user_friends.inspect}")
    @user_friends = User.where(id: @user_friend_ids)
    
    # find pending friends
    @pending_friend_ids = Friend.where(confirmed: [false, nil]).where("user_id = :this_user_id OR friend_id = :this_user_id", this_user_id: current_user.id)
          .pluck(:user_id, :friend_id).uniq.flatten(1) - [current_user.id]
    #Rails.logger.debug("Pending friends: #{@pending_friends.inspect}")  
    @pending_friends = User.where(id: @pending_friend_ids) 
    
    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end # end of process_friend_changes method
  
  def process_friend_changes_on_find_page
    # get data to add/update
    @data = params[:id]
    @data_split = @data.split("-")
    @status = @data_split[0]
    @action = @data_split[1]
    @id = @data_split[2]
    
    # update friend table
    if @status == "invited"
      if @action == "drop"
        @friend_status = Friend.where("user_id = :this_user_id OR friend_id = :this_user_id", this_user_id: current_user.id).
                                where("user_id = :this_user_id OR friend_id = :this_user_id", this_user_id: @id)[0]
        @friend_status.destroy!
      else
        @friend_status = Friend.where("user_id = :this_user_id OR friend_id = :this_user_id", this_user_id: current_user.id).
                                where("user_id = :this_user_id OR friend_id = :this_user_id", this_user_id: @id)[0]
        @friend_status.update(confirmed: true)
      end
    else
      @new_friend_request = Friend.create(user_id: current_user.id, friend_id: @id)
      @new_friend_request.save!
      
      @user = User.find_by_id(current_user.id)
      @invited_friend = User.find_by_id(@id)
      
      # send welcome email to customer
      UserMailer.friend_request(@invited_friend, @user).deliver_now
    end
    
    # find user's friends
    @user_friend_ids = Friend.where(confirmed: true).where("user_id = :this_user_id OR friend_id = :this_user_id", this_user_id: current_user.id)
          .pluck(:user_id, :friend_id).uniq.flatten(1) - [current_user.id]
    #Rails.logger.debug("User friends: #{@user_friends.inspect}")
    @user_friends = User.where(id: @user_friend_ids)
    
    # find pending friends
    @pending_friend_ids = Friend.where(confirmed: [false, nil]).where("user_id = :this_user_id OR friend_id = :this_user_id", this_user_id: current_user.id)
          .pluck(:user_id, :friend_id).uniq.flatten(1) - [current_user.id]
    #Rails.logger.debug("Pending friends: #{@pending_friends.inspect}")  
    @pending_friends = User.where(id: @pending_friend_ids) 
    
    # re-conduct search
    friend_search(session[:current_query])
    
    respond_to do |format|
      format.js { render 'process_friend_search.js.erb' }
    end # end of redirect to jquery
    
  end # end of process_friend_changes_on_find_page method
  
  private
  
  
end