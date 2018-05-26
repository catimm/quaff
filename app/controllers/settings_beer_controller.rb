class SettingsBeerController < ApplicationController
  include StyleDescriptors
  
  def beer_journey
    @category = "beer"
    # get user delivery preferences
    @user_delivery_preference = DeliveryPreference.find_by_user_id(current_user.id)
    
    # get user beer preferences
    @user_beer_preference = UserPreferenceBeer.find_by_user_id(current_user.id)
    if !@user_beer_preference.journey_stage.blank?
      # send beer_journey_stage data to js to show what is currently chosen
      gon.beer_journey_stage = @user_beer_preference.journey_stage
    end
    @last_saved = @user_beer_preference.updated_at

  end # end of beer_journey method
  
  def beer_numbers
    @category = "beer"
    @category_choice = "beers"
    @chosen_drinks_per_week = "hidden"
    
    # find user chosen categories
    @user_beer_preference = UserPreferenceBeer.find_by_user_id(current_user.id)
    if !@user_beer_preference.beers_per_week.nil?
      @chosen_drinks_per_week = "show"
      
      if (@user_beer_preference.beers_per_week % 1).zero?
        @drinks_per_week = @user_beer_preference.beers_per_week.round
        @chosen_timeframe = "week"
        @week_chosen = "chosen"
        @month_chosen = nil
        if @user_beer_preference.beers_per_week > 1
          @drinks_per_week_text = @drinks_per_week.to_s + " beers/week"
        else
          @drinks_per_week_text = @drinks_per_week.to_s + " beer/week" 
        end
      else
        @drinks_per_week = @user_beer_preference.beers_per_week * 4
        @chosen_timeframe = "month"
        @week_chosen = nil
        @month_chosen = "chosen"
        if @user_beer_preference.beers_per_week > 1
          @drinks_per_week_text = @drinks_per_week.to_s + " beers/week"
        else
          @drinks_per_week_text = @drinks_per_week.to_s + " beer/week" 
        end
      end
      
      if @beers_per_week != 0
        session[:beer_number] = @drinks_per_week
      end
      session[:beer_timeframe] = @chosen_timeframe
    end
    
    # set last saved
    @last_saved = @user_beer_preference.updated_at
    
  end # end of beer_numbers method
  
  def beer_styles
    @category = "beer"
    
    # get beer styles
    @styles_for_like = BeerStyle.where(signup_beer: true).order('style_order ASC')
    @beer_style_ids = @styles_for_like.pluck(:id)
    
    # find if user has already liked styles
    if current_user.role_id == 1 && params.has_key?(:format)
      # get user info
      @all_user_styles = UserStylePreference.where(user_id: params[:format])
    else
      # get user info
      @all_user_styles = UserStylePreference.where(user_id: current_user.id)
    end
    if !@all_user_styles.blank?
      @styles_updated_order = @all_user_styles.order('updated_at DESC')
      @last_saved = @styles_updated_order.first.updated_at
      @user_style_likes = @all_user_styles.where(user_preference: "like",
                                                    beer_style_id: @beer_style_ids).
                                                    pluck(:beer_style_id)
      @user_likes = @styles_for_like.where(master_style_id: @user_style_likes).pluck(:id)
      @user_style_dislikes = @all_user_styles.where(user_preference: "dislike",
                                                    beer_style_id: @beer_style_ids).
                                                    pluck(:beer_style_id)
      @user_dislikes = @styles_for_like.where(master_style_id: @user_style_dislikes).pluck(:id)
    end
  end # end of beer_style_likes method
  
  def beer_priorities
    @category = "beer"

    @user_preferences = DeliveryPreference.find_by_user_id(current_user.id)
    
    #@user_priorities = UserPriority.new
    @priorties = Priority.where(beer_relevant: true)
    
    #check if user has already chosen this question
    @priority_list = UserPriority.where(user_id: current_user.id, category: "beer")
    if !@priority_list.blank?
      @user_priorities = @priority_list.order('priority_rank ASC')
      @updated_order = @priority_list.order('updated_at DESC')
      @last_saved = @updated_order.first.updated_at
    end
    
    if !@user_priorities.blank?
      @priority_choice_header = "show"
      @chosen_priorities = @user_priorities.pluck(:priority_id)
    else
      @priority_choice_header = "hidden"
    end
  end # end beer_priorities method
  
  def beer_costs
    # set referring page
    @referring_url = request.referrer
    
    @category = "beer"
    
    # get current user input
    @user_preferences = DeliveryPreference.find_by_user_id(current_user.id)
    
    @user_beer_preferences = UserPreferenceBeer.find_by_user_id(current_user.id)
    @last_saved = @user_beer_preferences.updated_at
    @drink_estimate = @user_beer_preferences.beer_price_estimate
    if !@user_beer_preferences.beer_price_response.nil?
      if @user_beer_preferences.beer_price_response == "lower"
        @option_lower = "chosen"
      elsif @user_beer_preferences.beer_price_response == "middle"
        @option_middle = "chosen"
      else
        @option_higher = "chosen"
      end
    end
    if !@user_beer_preferences.beer_price_limit.nil?
      # send beer_price_limit data to js to show what is currently chosen
      gon.beer_price_limit = @user_beer_preferences.beer_price_limit.round
    end
    
  end # end beer_costs method
  
  def beer_extras
    @user_beer_preferences = UserPreferenceBeer.find_by_user_id(current_user.id)
    if !@user_beer_preferences.additional.nil?
      @last_saved = @user_beer_preferences.updated_at
    end
  end # end beer_extras method
  
  def process_beer_extras
    # get inpu
    @beer_additional = params[:user_preference_beer][:additional]
    # get user info
    @user_beer_preferences = UserPreferenceBeer.find_by_user_id(current_user.id)
    if @user_beer_preferences.update(additional: @beer_additional)
      redirect_to settings_beer_extras_path
    end
  end # end process_beer_extras method
  
end # end of controller