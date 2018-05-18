class SettingsWineController < ApplicationController
  include StyleDescriptors
  
  def wine_journey
    @category = "wine"
    # get user delivery preferences
    @user_delivery_preference = DeliveryPreference.find_by_user_id(current_user.id)
    
    # get user wine preferences
    @user_wine_preference = UserPreferenceWine.find_by_user_id(current_user.id)
    if !@user_wine_preference.journey_stage.blank?
      # send wine_journey_stage data to js to show what is currently chosen
      gon.wine_journey_stage = @user_wine_preference.journey_stage
    end
    @last_saved = @user_wine_preference.updated_at

  end # end of wine_journey method
  
  def wine_numbers
    @category = "wine"
    @category_choice = "glasses of wine"
    @chosen_drinks_per_week = "hidden"
    
    # find user chosen categories
    @user_wine_preference = UserPreferenceWine.find_by_user_id(current_user.id)
    if !@user_wine_preference.glasses_per_week.nil?
      @chosen_drinks_per_week = "show"
      
      if (@user_wine_preference.glasses_per_week % 1).zero?
        @drinks_per_week = @user_wine_preference.glasses_per_week.round
        @chosen_timeframe = "week"
        @week_chosen = "chosen"
        @month_chosen = nil
        if @user_wine_preference.glasses_per_week > 1
          @drinks_per_week_text = @drinks_per_week.to_s + " glasses/week"
        else
          @drinks_per_week_text = @drinks_per_week.to_s + " glass/week" 
        end
      else
        @drinks_per_week = @user_wine_preference.glasses_per_week * 4
        @chosen_timeframe = "month"
        @week_chosen = nil
        @month_chosen = "chosen"
        if @user_wine_preference.glasses_per_week > 1
          @drinks_per_week_text = @drinks_per_week.to_s + " glasses/week"
        else
          @drinks_per_week_text = @drinks_per_week.to_s + " glass/week" 
        end
      end
      
      if @glasses_per_week != 0
        session[:wine_number] = @drinks_per_week
      end
      session[:wine_timeframe] = @chosen_timeframe
    end
    
    # set last saved
    @last_saved = @user_wine_preference.updated_at
    
  end # end of wine_numbers method
  
  def wine_styles
    @category = "wine"
    
    # get beer styles
    @styles_for_like = BeerStyle.where(signup_wine: true).order('style_order ASC')
    @wine_style_ids = @styles_for_like.pluck(:id)
    
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
                                                    beer_style_id: @wine_style_ids).
                                                    pluck(:beer_style_id)
      @user_likes = @styles_for_like.where(master_style_id: @user_style_likes).pluck(:id)
      @user_style_dislikes = @all_user_styles.where(user_preference: "dislike",
                                                    beer_style_id: @wine_style_ids).
                                                    pluck(:beer_style_id)
      @user_dislikes = @styles_for_like.where(master_style_id: @user_style_dislikes).pluck(:id)
    end
       
  end # end of wine_style_likes method
  
  def wine_extras
    @user_wine_preferences = UserPreferenceWine.find_by_user_id(current_user.id)
    if !@user_wine_preferences.additional.nil?
      @last_saved = @user_wine_preferences.updated_at
    end
  end # end wine_extras method
  
  def process_wine_extras
    # get inpu
    @wine_additional = params[:user_preference_wine][:additional]
    # get user info
    @user_wine_preferences = UserPreferenceWine.find_by_user_id(current_user.id)
    if @user_wine_preferences.update(additional: @wine_additional)
      redirect_to settings_wine_extras_path
    end
  end # end process_wine_extras method
  
end # end of controller