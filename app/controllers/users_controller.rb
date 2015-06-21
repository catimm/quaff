class UsersController < ApplicationController
  before_filter :authenticate_user!
  
  def index
    
  end
  
  def show
  
  end
  
  def update
    if DrinkList.where(:user_id => current_user.id, :beer_id => params[:beer]).blank?
      new_drink = DrinkList.new(:user_id => current_user.id, :beer_id => params[:beer])
      new_drink.save!
    else
      find_drink = DrinkList.where(:user_id => current_user.id, :beer_id => params[:beer]).pluck(:id)
      destroy_drink = DrinkList.find(find_drink)[0]
      destroy_drink.destroy!
    end  
    respond_to do |format|
      format.js
    end
  end
  
  def style_preferences
    
  end
  
end