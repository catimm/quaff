class SignupController < ApplicationController
  
  def getting_started
    # get current view
    if params[:id].include? '-'
      @data = params[:id]
      @data_split = @data.split("-")
      @view = @data_split[0]
      @step = @data_split[1]
    else
      @view = params[:id]
      @step = 1
    end
    
    # get User info 
    @user = User.find(current_user.id)
    
    # get Delivery Preference info if it exists
    @delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first
    
    if @view == "category"
      # set css rule for signup guide header
      @category_chosen = "current"
      # get Delivery Preference info if it exists
      if !@delivery_preferences.blank?
        if @delivery_preferences.drink_option_id == 1
          @beer_chosen = "show"
          @cider_chosen = "hidden"
          @beer_and_cider_chosen = "hidden"
        elsif @delivery_preferences.drink_option_id == 2
          @beer_chosen = "hidden"
          @cider_chosen = "show"
          @beer_and_cider_chosen = "hidden"
        else
          @beer_chosen = "hidden"
          @cider_chosen = "hidden"
          @beer_and_cider_chosen = "show"
        end
      end
      
    elsif @view == "journey"
      # set css rule for signup guide header
      @journey_chosen = "current"
      # set drink category choice
      if @delivery_preferences.drink_option_id == 1
        @drink_preference = "beer"
      elsif @delivery_preferences.drink_option_id == 2
        @drink_preference = "cider"
      else
        @drink_preference = "beer/cider"
      end
      
      # set user craft stage if it exists
      if @user.craft_stage_id == 1
        @casual_chosen = "show"
        @geek_chosen = "hidden"
        @conn_chosen = "hidden"
      elsif @user.craft_stage_id == 2
        @casual_chosen = "hidden"
        @geek_chosen = "show"
        @conn_chosen = "hidden"
      elsif @user.craft_stage_id == 3
        @casual_chosen = "hidden"
        @geek_chosen = "hidden"
        @conn_chosen = "show"
      else
        @casual_chosen = "hidden"
        @geek_chosen = "hidden"
        @conn_chosen = "hidden"
      end
    elsif @view == "styles"
      # set css rule for signup guide header
      @styles_chosen = "current"
      
      # set style list
      if @delivery_preferences.drink_option_id == 1
        @styles = BeerStyle.where(signup_beer: true)
      elsif @delivery_preferences.drink_option_id == 2
        @styles = BeerStyle.where(signup_cider: true)
      else
        @styles = BeerStyle.where(signup_beer_cider: true)
      end
      
      
    elsif @view == "preferences"
      # set css rule for signup guide header
      @preferences_chosen = "current"
      
      
    else
      # set css rule for signup guide header
      @account_chosen = "current"
      
      
    end
  end # end of signup method
  
  def process_input
    # get data
    @data = params[:id]
    @data_split = @data.split("-")
    @view = @data_split[0]
    @step = @data_split[1]
    @input = @data_split[2]
    
    # get User info 
    @user = User.find(current_user.id)
    
    # get Delivery Preference info if it exists
    @delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first
    
    if @view == "category"
      # save the drink category data
      if !@delivery_preferences.blank?
        @delivery_preferences.update(drink_option_id: @input)
      else
        @new_delivery_preference = DeliveryPreference.create(user_id: current_user.id, drink_option_id: @input)
      end
      
      # set next view
      @next_step = "journey"
      
    elsif @view == "journey"
      # save the user craft stage data
      @user.update(craft_stage_id: @input)
      
      # set next view
      @next_step = "styles-1"
      
    elsif @view == "styles"
      
      
    elsif @view == "preferences"
      
      
    else
      
      
    end
    
    # redirect
    render js: "window.location = '#{getting_started_path(@next_step)}'"
  end # end of process_input method
  
end # end of controller