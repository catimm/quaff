class ConnectionsController < ApplicationController
  before_action :authenticate_user!
  include FriendSearch
  require 'json'
  
  def manage_friends
    # find user's friends
    @user_friend_ids = Friend.where(confirmed: true).where("user_id = :this_user_id OR friend_id = :this_user_id", this_user_id: current_user.id)
          .pluck(:user_id, :friend_id).uniq.flatten(1) - [current_user.id]
    #Rails.logger.debug("User friends: #{@user_friends.inspect}")
    @user_friends = User.where(id: @user_friend_ids)
    
    # find pending friends
    @pending_friend_ids = Friend.where(confirmed: [false, nil]).where("user_id = :this_user_id OR friend_id = :this_user_id", this_user_id: current_user.id)
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
  
  def add_connection
    @friend_id = params[:id]
    
    @friend_status = Friend.where("(user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)", current_user.id, @friend_id, @friend_id, current_user.id)[0]
    if !@friend_status.blank?
      @friend_status.update(confirmed: true)
    else
      Friend.create(user_id: current_user.id, friend_id: @friend_id, confirmed: false, mate: false)
    end
    
    # send back to manage friends page
    render js: "window.location = '#{manage_friends_path}'"
    
  end # end add_connection method
  
  def remove_connection
    @friend_id = params[:id]
    
    @friend_status = Friend.where("(user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)", current_user.id, @friend_id, @friend_id, current_user.id)[0]
    @friend_status.destroy!
    
    # send back to manage friends page
    render js: "window.location = '#{manage_friends_path}'"
    
  end # end remove_connections method
  
  def invite_connection_reminder
    @friend = User.find_by_id(params[:id])
    
    # if friend already has a Knird account
    if !@friend.account_id.nil?
      # send connection invite email
      UserMailer.friend_request(@friend, current_user).deliver_now
    else 
      #resend the Inivtation to Join Knird 
      UserMailer.friend_invite_email(@friend, current_user).deliver_now
    end
      
    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end # end of invite_connection_reminder method
  
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

end # end of controller