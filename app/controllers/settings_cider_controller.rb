class SettingsCiderController < ApplicationController
  include StyleDescriptors
  
  def cider_journey
    @category = "cider"
    # get user delivery preferences
    @user_delivery_preference = DeliveryPreference.find_by_user_id(current_user.id)
    
    # get user cider preferences
    @user_cider_preference = UserPreferenceCider.find_by_user_id(current_user.id)
    if !@user_cider_preference.journey_stage.blank?
      # send cider_journey_stage data to js to show what is currently chosen
      gon.cider_journey_stage = @user_cider_preference.journey_stage
    end
    @last_saved = @user_cider_preference.updated_at

  end # end of cider_journey method
  
  def cider_numbers
    @category = "cider"
    @category_choice = "ciders"
    @chosen_drinks_per_week = "hidden"
    
    # find user chosen categories
    @user_cider_preference = UserPreferenceCider.find_by_user_id(current_user.id)
    if !@user_cider_preference.ciders_per_week.nil?
      @chosen_drinks_per_week = "show"
      
      if (@user_cider_preference.ciders_per_week % 1).zero?
        @drinks_per_week = @user_cider_preference.ciders_per_week.round
        @chosen_timeframe = "week"
        @week_chosen = "chosen"
        @month_chosen = nil
        if @user_cider_preference.ciders_per_week > 1
          @drinks_per_week_text = @drinks_per_week.to_s + " ciders/week"
        else
          @drinks_per_week_text = @drinks_per_week.to_s + " cider/week" 
        end
      else
        @drinks_per_week = @user_cider_preference.ciders_per_week * 4
        @chosen_timeframe = "month"
        @week_chosen = nil
        @month_chosen = "chosen"
        if @user_cider_preference.ciders_per_week > 1
          @drinks_per_week_text = @drinks_per_week.to_s + " ciders/week"
        else
          @drinks_per_week_text = @drinks_per_week.to_s + " cider/week" 
        end
      end
      
      if @ciders_per_week != 0
        session[:cider_number] = @drinks_per_week
      end
      session[:cider_timeframe] = @chosen_timeframe
    end
    
    # set last saved
    @last_saved = @user_cider_preference.updated_at
    
  end # end of cider_numbers method
  
  def cider_styles
    @category = "cider"
    
    # get cider styles
    @styles_for_like = BeerStyle.where(signup_cider: true).order('style_order ASC')
    @cider_style_ids = @styles_for_like.pluck(:id)
    
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
                                                    beer_style_id: @cider_style_ids).
                                                    pluck(:beer_style_id)
      @user_likes = @styles_for_like.where(master_style_id: @user_style_likes).pluck(:id)
      @user_style_dislikes = @all_user_styles.where(user_preference: "dislike",
                                                    beer_style_id: @cider_style_ids).
                                                    pluck(:beer_style_id)
      @user_dislikes = @styles_for_like.where(master_style_id: @user_style_dislikes).pluck(:id)
    end
       
  end # end of cider_style_likes method
  
  def cider_priorities
    @category = "cider"

    @user_preferences = DeliveryPreference.find_by_user_id(current_user.id)
    
    #@user_priorities = UserPriority.new
    @priorties = Priority.where(cider_relevant: true)
    
    #check if user has already chosen this question
    @priority_list = UserPriority.where(user_id: current_user.id, category: "cider")
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
  end # end cider_priorities method
  
  def cider_costs
    @category = "cider"
    
    # get current user input
    @user_preferences = DeliveryPreference.find_by_user_id(current_user.id)
    
    @user_cider_preferences = UserPreferenceCider.find_by_user_id(current_user.id)
    @last_saved = @user_cider_preferences.updated_at
    @drink_estimate = @user_cider_preferences.cider_price_estimate
    if !@user_cider_preferences.cider_price_response.nil?
      if @user_cider_preferences.cider_price_response == "lower"
        @option_lower = "chosen"
      elsif @user_cider_preferences.cider_price_response == "middle"
        @option_middle = "chosen"
      else
        @option_higher = "chosen"
      end
    end
    if !@user_cider_preferences.cider_price_limit.nil?
      # send cider_price_limit data to js to show what is currently chosen
      gon.cider_price_limit = @user_cider_preferences.cider_price_limit.round
    end
    
  end # end cider_costs method
  
  def cider_extras
    @user_cider_preferences = UserPreferenceCider.find_by_user_id(current_user.id)
    if !@user_cider_preferences.additional.nil?
      @last_saved = @user_cider_preferences.updated_at
    end
  end # end cider_extras method
  
  def process_cider_extras
    # get input
    @cider_additional = params[:user_preference_cider][:additional]
    # get user info
    @user_cider_preferences = UserPreferenceCider.find_by_user_id(current_user.id)
    if @user_cider_preferences.update(additional: @cider_additional)
      redirect_to settings_cider_extras_path
    end
  end # end process_cider_extras method
  
end # end of controller