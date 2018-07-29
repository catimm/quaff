class CreateDrinkProfileController < ApplicationController
  include DeliveryEstimator
  include StyleDescriptors
  require 'faker'
  
  def start_consumer_drink_profile
    # first create an account
    @account = Account.create!(account_type: "consumer", number_of_users: 1)
    
    # next create fake user profile
    @fake_user_email = Faker::Internet.unique.email
    @generated_password = Devise.friendly_token.first(8)
    
    # create new user
    @user = User.create(account_id: @account.id, 
                        email: @fake_user_email, 
                        password: @generated_password,
                        password_confirmation: @generated_password,
                        role_id: 4,
                        getting_started_step: 0,
                        unregistered: true)
    
    if @user.save
      # Sign in the new user by passing validation
      bypass_sign_in(@user)
    end     
                  
    # redirect
    redirect_to drink_profile_categories_path
    
  end # end of start_consumer_drink_profile method
  
  def drink_categories 
    # indicate this is coming from signup
    @create_drink_profile = true
    
    # set defaults
    @beer_chosen = 'hidden'
    @cider_chosen = 'hidden'
    @wine_chosen = 'hidden'
    
    if user_signed_in?
      # get user info
      @user = User.find_by_id(current_user.id)
      # send getting started step to jquery
      gon.getting_started_step = @user.getting_started_step
      
      # find if user has already chosen categories
      @user_preferences = DeliveryPreference.find_by_user_id(@user.id)
      
      if !@user_preferences.blank?
        if @user_preferences.beer_chosen == true
          @beer_chosen = 'show'
        end
        if @user_preferences.cider_chosen == true
          @cider_chosen = 'show'
        end
        if @user_preferences.wine_chosen == true
          @wine_chosen = 'show'
        end  
      end
    else
      gon.getting_started_step = 0
    end

  end # end of drink_categories method
  
  def process_drink_categories
    if !user_signed_in?
      # first create an account
      @account = Account.create!(account_type: "consumer", number_of_users: 1)
      
      # next create fake user profile
      @fake_user_email = Faker::Internet.unique.email
      @generated_password = Devise.friendly_token.first(8)
      
      # create new user
      @user = User.create(account_id: @account.id, 
                          email: @fake_user_email, 
                          password: @generated_password,
                          password_confirmation: @generated_password,
                          role_id: 4,
                          getting_started_step: 0,
                          unregistered: true)
      
      if @user.save
        # Sign in the new user by passing validation
        bypass_sign_in @user
      end 
    else
      @user = current_user
    end # end of creating using acct
      
    # set referring page
    @referring_url = request.referrer
    
    # get data
    @data = params[:id]
    @split_data = @data.split("-")
    @action = @split_data[0]
    @category = @split_data[1]
    
    # check if user already has a delivery preference entry
    @user_delivery_preference = DeliveryPreference.find_by_user_id(@user.id)
    
    if @referring_url.include?("delivery_settings") && @action == "remove"
      @number_chosen = 0
      if @user_delivery_preference.beer_chosen == true
        @number_chosen = @number_chosen + 1
      end
      if @user_delivery_preference.cider_chosen == true
        @number_chosen = @number_chosen + 1
      end
      if @user_delivery_preference.wine_chosen == true
        @number_chosen = @number_chosen + 1
      end
    end
    #Rails.logger.debug("Number chosen: #{@number_chosen.inspect}")  
    if @referring_url.include?("create_drink_profile") || @action == "add" || (@action == "remove" && @number_chosen >= 2)
     #Rails.logger.debug("Hits first option") 
      # create table entries where needed
      if !@user_delivery_preference.blank?
        if @category == "beer" 
          if @action == "add"
            if @user_delivery_preference.update(beer_chosen: true)
              @user_beer_preference = UserPreferenceBeer.create(user_id: @user.id,
                                                              delivery_preference_id: @user_delivery_preference.id)
              if @user_beer_preference.save
                @choice_saved = true
                @beer_category = true
              else
                @user_delivery_preference.update(beer_chosen: nil)
              end
            end
          else
            if @user_delivery_preference.update(beer_chosen: nil)
              @user_beer_preference = UserPreferenceBeer.find_by_user_id(@user.id)
              if @user_beer_preference.destroy
                @choice_saved = true
                @beer_category = false
              else
                @user_delivery_preference.update(beer_chosen: true)
              end
            end
          end
          @last_saved = @user_beer_preference.updated_at
        end # end of beer check
        if @category == "cider" 
          if @action == "add"
            if @user_delivery_preference.update(cider_chosen: true)
              @user_cider_preference = UserPreferenceCider.create(user_id: @user.id,
                                                            delivery_preference_id: @user_delivery_preference.id)
              if @user_cider_preference.save
                @choice_saved = true
                @cider_category = true
              else
                @user_delivery_preference.update(cider_chosen: nil)
              end
            end
          else
            if @user_delivery_preference.update(cider_chosen: nil)
              @user_cider_preference = UserPreferenceCider.find_by_user_id(@user.id)
              if @user_cider_preference.destroy
                @choice_saved = true
                @cider_category = false
              else
                @user_delivery_preference.update(cider_chosen: true)
              end
            end
          end
          @last_saved = @user_cider_preference.updated_at
        end # end of cider check
        if @category == "wine" 
          if @action == "add"
            if @user_delivery_preference.update(wine_chosen: true)
              @user_wine_preference = UserPreferenceWine.create(user_id: @user.id,
                                                              delivery_preference_id: @user_delivery_preference.id)
              if @user_wine_preference.save
                @choice_saved = true
                @wine_category = true
              else
                @user_delivery_preference.update(wine_chosen: nil)
              end
            end
          else
            if @user_delivery_preference.update(wine_chosen: nil)
              @user_wine_preference = UserPreferenceWine.find_by_user_id(@user.id)
              if @user_wine_preference.destroy
                @choice_saved = true
                @wine_category = false
              else
                @user_delivery_preference.update(wine_chosen: true)
              end
            end
          end
          @last_saved = @user_wine_preference.updated_at
        end # end of wine check
      else # if user delivery preference doesn't exist
        if @category == "beer"
          # create delivery preference and chosen drink preference
          @user_delivery_preference = DeliveryPreference.create(user_id: @user.id,
                                                                  beer_chosen: true)
          if @user_delivery_preference.save
            @user_beer_preference = UserPreferenceBeer.create(user_id: @user.id,
                                                              delivery_preference_id: @user_delivery_preference.id)
            if @user_beer_preference.save
              @choice_saved = true
              @beer_category = true
            end
          end
        end # end of beer chosen
        
        if @category == "cider"
          # create delivery preference and chosen drink preference
          @user_delivery_preference = DeliveryPreference.create(user_id: @user.id,
                                                                  cider_chosen: true)
          if @user_delivery_preference.save
            @user_cider_preference = UserPreferenceCider.create(user_id: @user.id,
                                                              delivery_preference_id: @user_delivery_preference.id)
            if @user_cider_preference.save
              @choice_saved = true
              @cider_category = true
            end
          end
        end # end of cider chosen
        
        if @category == "wine"
          # create delivery preference and chosen drink preference
          @user_delivery_preference = DeliveryPreference.create(user_id: @user.id,
                                                                  wine_chosen: true)
          if @user_delivery_preference.save
            @user_wine_preference = UserPreferenceWine.create(user_id: @user.id,
                                                              delivery_preference_id: @user_delivery_preference.id)
            if @user_wine_preference.save
              @choice_saved = true
              @wine_category = true
            end
          end
        end # end of wine chosen
        
      end # end of check whether user already has a delivery preference entry 
    else # making sure at least 1 category is chosen
      #Rails.logger.debug("Hits second option") 
      @need_at_least_one_category = true
    end
    # check how many categories are currently chosen for 'next' button
    if @user_delivery_preference.beer_chosen == true
      @category_count = 1
    elsif @user_delivery_preference.cider_chosen == true
      @category_count = 1
    elsif @user_delivery_preference.wine_chosen == true
      @category_count = 1
    else
      @category_count = 0
    end
    # redirect as appropriate
    respond_to do |format|
      format.js
    end
    
  end # end of process_drink_categories
  
  #def beer_journey
  #  # set getting started step
  #  @user = current_user
  #  if @user.getting_started_step < 1
  #    @user.update_attribute(:getting_started_step, 1) # because current_user is not an object, "update_attributes" needs to be used instead of just "update"
  #  end
  #  
    # set UX variables
  #  @category = "beer"
  #  @beer_chosen = "current"
  #  @journey_chosen = "current"
  #  
    # indicate this is coming from signup
  #  @create_drink_profile = true
  #  
    # get user delivery preferences
  #  @user_delivery_preference = DeliveryPreference.find_by_user_id(current_user.id)
    
    # get user beer preferences
  #  @user_beer_preference = UserPreferenceBeer.find_by_user_id(current_user.id)
    # send beer_journey_stage data to js to show what is currently chosen
  #  gon.beer_journey_stage = @user_beer_preference.journey_stage
    
  #  @last_saved = @user_beer_preference.updated_at
  
 # end # end of beer_journey method
  
  #def cider_journey
  #  # set getting started step
  #  @user = current_user
  #  if @user.getting_started_step < 6
  #    @user.update_attribute(:getting_started_step, 6) # because current_user is not an object, "update_attributes" needs to be used instead of just "update"
  #  end
    
    # set UX variables
  #  @category = "cider"
  #  @beer_chosen = "complete"
  #  @cider_chosen = "current"
  #  @journey_chosen = "current"
    
    # indicate this is coming from signup
  #  @create_drink_profile = true
    
    # get user delivery preferences
  #  @user_delivery_preference = DeliveryPreference.find_by_user_id(current_user.id)
    
    # get user cider preferences
  #  @user_cider_preference = UserPreferenceCider.find_by_user_id(current_user.id)
    # send beer_journey_stage data to js to show what is currently chosen
  #  gon.cider_journey_stage = @user_cider_preference.journey_stage

  #  @last_saved = @user_cider_preference.updated_at
  
  #end # end of cider_journey method
  
  #def wine_journey
    # set getting started step
  #  @user = current_user
  #  if @user.getting_started_step < 11
  #    @user.update_attribute(:getting_started_step, 11) # because current_user is not an object, "update_attributes" needs to be used instead of just "update"
  #  end
    
    # set UX variables
  #  @category = "wine"
  #  @beer_chosen = "complete"
  #  @cider_chosen = "complete"
  #  @wine_chosen = "current"
  #  @journey_chosen = "current"
    
    # indicate this is coming from signup
  #  @create_drink_profile = true
    
    # get user delivery preferences
  #  @user_delivery_preference = DeliveryPreference.find_by_user_id(current_user.id)
    
    # get user wine preferences
  #  @user_wine_preference = UserPreferenceWine.find_by_user_id(current_user.id)
    # send beer_journey_stage data to js to show what is currently chosen
  #  gon.wine_journey_stage = @user_wine_preference.journey_stage

  #  @last_saved = @user_wine_preference.updated_at
  
  #end # end of wine_journey method
  
  def process_drink_journey
    # set referring page
    @referring_url = request.referrer
    
    # get data
    @data = params[:id]
    @split_data = @data.split("-")
    @category = @split_data[0]
    @journey_stage = @split_data[1].to_i

    if @category == "beer"
      @user_beer_preference = UserPreferenceBeer.find_by_user_id(current_user.id)
      if @user_beer_preference.update(journey_stage: @journey_stage)
        @choice_saved = true
      end
      @last_saved = @user_beer_preference.updated_at
    elsif @category == "cider"
      @user_cider_preference = UserPreferenceCider.find_by_user_id(current_user.id)
      if @user_cider_preference.update(journey_stage: @journey_stage)
        @choice_saved = true
      end
      @last_saved = @user_cider_preference.updated_at
    else
      @user_wine_preference = UserPreferenceWine.find_by_user_id(current_user.id)
      if @user_wine_preference.update(journey_stage: @journey_stage)
        @choice_saved = true
      end
      @last_saved = @user_wine_preference.updated_at
    end
    
    respond_to do |format|
      format.js
    end
    
  end # end of process_drink_journey method
  
  def beer_numbers
    # set getting started step
    @user = current_user
    if @user.getting_started_step < 10
      @user.update_attribute(:getting_started_step, 10) # because current_user is not an object, "update_attributes" needs to be used instead of just "update"
    end
    # set UX variables
    @category = "beer"
    @category_choice = "beers"
    @chosen_drinks_per_week = "hidden"
    @user_chosen = "complete"
    @drink_chosen = "current"
    @beer_chosen = "current"
    @subguide = "drink"
    
    # indicate this is coming from signup
    @create_drink_profile = true
    
    # get user delivery preferences
    @user_delivery_preference = DeliveryPreference.find_by_user_id(current_user.id)
    
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
  
  def cider_numbers
    # set getting started step
    @user = current_user
    if @user.getting_started_step < 11
      @user.update_attribute(:getting_started_step, 11) # because current_user is not an object, "update_attributes" needs to be used instead of just "update"
    end
    
    # set UX variables
    @category = "cider"
    @category_choice = "ciders"
    @chosen_drinks_per_week = "hidden"
    @beer_chosen = "complete"
    @cider_chosen = "current"
    @user_chosen = "complete"
    @drink_chosen = "current"
    @subguide = "drink"
    
    # indicate this is coming from signup
    @create_drink_profile = true
    
    # get user delivery preferences
    @user_delivery_preference = DeliveryPreference.find_by_user_id(current_user.id)
    
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
      
      if @drinks_per_week != 0
        session[:cider_number] = @drinks_per_week
      end
      session[:cider_timeframe] = @chosen_timeframe
    end
    
    # set last saved
    @last_saved = @user_cider_preference.updated_at
    
  end # end of cider_numbers method
  
  #def wine_numbers
    # set getting started step
  #  @user = current_user
  #  if @user.getting_started_step < 12
  #    @user.update_attribute(:getting_started_step, 12) # because current_user is not an object, "update_attributes" needs to be used instead of just "update"
  #  end
    
    # set UX variables
  #  @category = "wine"
  #  @category_choice = "glasses of wine"
  #  @chosen_drinks_per_week = "hidden"
  #  @beer_chosen = "complete"
  #  @cider_chosen = "complete"
  #  @wine_chosen = "current"
  #  @journey_chosen = 'complete'
  #  @numbers_chosen = 'current'
    
    # indicate this is coming from signup
  #  @create_drink_profile = true
    
    # get user delivery preferences
  #  @user_delivery_preference = DeliveryPreference.find_by_user_id(current_user.id)
    
    # find user chosen categories
  #  @user_wine_preference = UserPreferenceWine.find_by_user_id(current_user.id)
  #  if !@user_wine_preference.glasses_per_week.nil?
  #    @chosen_drinks_per_week = "show"
      
  #    if (@user_wine_preference.glasses_per_week % 1).zero?
  #      @drinks_per_week = @user_wine_preference.glasses_per_week.round
  #      @chosen_timeframe = "week"
  #      @week_chosen = "chosen"
  #      @month_chosen = nil
  #      if @user_wine_preference.glasses_per_week > 1
  #        @drinks_per_week_text = @drinks_per_week.to_s + " glasses/week"
  #      else
  #        @drinks_per_week_text = @drinks_per_week.to_s + " glass/week" 
  #      end
  #    else
  #      @drinks_per_week = @user_wine_preference.glasses_per_week * 4
  #      @chosen_timeframe = "month"
  #      @week_chosen = nil
  #      @month_chosen = "chosen"
  #      if @user_wine_preference.glasses_per_week > 1
  #        @drinks_per_week_text = @drinks_per_week.to_s + " glasses/week"
  #      else
  #        @drinks_per_week_text = @drinks_per_week.to_s + " glass/week" 
  #      end
  #    end
      
  #    if @drinks_per_week != 0
  #      session[:wine_number] = @drinks_per_week
  #    end
  #    session[:wine_timeframe] = @chosen_timeframe
  #  end
    
    # set last saved
  #  @last_saved = @user_wine_preference.updated_at
    
  #end # end of wine_numbers method
  
  def process_drinks_per_week
    # set referring page
    @referring_url = request.referrer
    
    # get data
    @data = params[:id]
    @split_data = @data.split("-")
    @category = @split_data[0]
    @type = @split_data[1]
    @input = @split_data[2]
    
    # get user account info to check for chosen frequency
    @account = Account.find_by_id(current_user.account_id)
    
    # set default time saved
    @last_saved = Time.now
    
    if @type == "timeframe"
      @timeframe_saved = true
      if @category == "beer"
        session[:beer_timeframe] = @input
        @beer_timeframe = @input
      end
      if @category == "cider"
        session[:cider_timeframe] = @input
        @cider_timeframe = @input
      end
      if @category == "wine"
        session[:wine_timeframe] = @input
        @wine_timeframe = @input
      end
    end
    
    if @type == "number"
      if @category == "beer"
        session[:beer_number] = @input.to_f
      end
      if @category == "cider"
        session[:cider_number] = @input.to_f
      end
      if @category == "wine"
        session[:wine_number] = @input.to_f
      end
    end
    
    # add data to table if ready
    @drinks_per_week = nil
    
    if @category == "beer"
      if session[:beer_timeframe] && session[:beer_number]
        if session[:beer_timeframe] == "week"
          @beer_drinks_per_week = session[:beer_number].to_i
        else
          @beer_drinks_per_week = session[:beer_number].to_f / 4
        end
        @user_beer_preference = UserPreferenceBeer.find_by_user_id(current_user.id)
        if @account.delivery_frequency.nil?
          @beers_per_delivery = nil
        else
          @beers_per_delivery = @beer_drinks_per_week * @account.delivery_frequency.to_i
        end
        if @user_beer_preference.update(beers_per_week: @beer_drinks_per_week.to_f, beers_per_delivery: @beers_per_delivery)
          @chosen_drinks_per_week = "show"
          if @beer_drinks_per_week > 1
            @drinks_per_week_text = @beer_drinks_per_week.to_s + " beers/week"
          else
            @drinks_per_week_text = @beer_drinks_per_week.to_s + " beer/week" 
          end
          @last_saved = @user_beer_preference.updated_at
        end
      end
    end # end of beer category check
    
    if @category == "cider"
      if session[:cider_timeframe] && session[:cider_number]
        if session[:cider_timeframe] == "week"
          @cider_drinks_per_week = session[:cider_number].to_i
        else
          @cider_drinks_per_week = session[:cider_number].to_f / 4
        end
        @user_cider_preference = UserPreferenceCider.find_by_user_id(current_user.id)
        if @account.delivery_frequency.nil?
          @ciders_per_delivery = nil
        else
          @ciders_per_delivery = @cider_drinks_per_week * @account.delivery_frequency.to_i
        end
        if @user_cider_preference.update(ciders_per_week: @cider_drinks_per_week.to_f, ciders_per_delivery: @ciders_per_delivery)
          @chosen_drinks_per_week = "show"
          if @cider_drinks_per_week > 1
            @drinks_per_week_text = @cider_drinks_per_week.to_s + " ciders/week"
          else
             @drinks_per_week_text = @cider_drinks_per_week.to_s + " cider/week" 
          end
          @last_saved = @user_cider_preference.updated_at
        end
      end
    end # end of cider category check
    
    if @category == "wine"
      if session[:wine_timeframe] && session[:wine_number]
        if session[:wine_timeframe] == "week"
          @wine_drinks_per_week = session[:wine_number].to_i
        else
          @wine_drinks_per_week = session[:wine_number].to_f / 4
        end
        @user_wine_preference = UserPreferenceWine.find_by_user_id(current_user.id)
        if @user_wine_preference.update(glasses_per_week: @wine_drinks_per_week.to_f)
          @chosen_drinks_per_week = "show"
          if @wine_drinks_per_week > 1
            @drinks_per_week_text = @wine_drinks_per_week.to_s + " glasses/week"
          else
             @drinks_per_week_text = @wine_drinks_per_week.to_s + " glass/week" 
          end
          @last_saved = @user_wine_preference.updated_at
        end
      end
    end # end of wine category check
      
    # Rails.logger.debug("Text: #{@drinks_per_week_text.inspect}")
    respond_to do |format|
      format.js
    end
      
  end # end of process_drinks_per_week method
  
  def beer_styles
    # remove session variables from previous step
    session.delete(:beer_timeframe)
    session.delete(:beer_number)
    
    # set getting started step
    @user = current_user
    if @user.getting_started_step < 1
      @user.update_attribute(:getting_started_step, 1) # because current_user is not an object, "update_attributes" needs to be used instead of just "update"
    end
    
    # set UX variables
    @category = "beer"
    @beer_chosen = "current"
    @styles_chosen = 'current'
    
    # indicate this is coming from signup
    @create_drink_profile = true
    
    # get user delivery preferences
    @user_delivery_preference = DeliveryPreference.find_by_user_id(current_user.id)
    
    # get beer styles
    @styles_for_like = BeerStyle.where(signup_beer: true).order('style_order ASC')
    @beer_style_ids = @styles_for_like.pluck(:id)
    
    # find if user has already liked styles
    @all_user_styles = UserStylePreference.where(user_id: current_user.id)
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
    
  end # end of beer_styles method
  
  def cider_styles
    # remove session variables from previous step
    session.delete(:cider_timeframe)
    session.delete(:cider_number)
    
    # set getting started step
    @user = current_user
    if @user.getting_started_step < 3
      @user.update_attribute(:getting_started_step, 3) # because current_user is not an object, "update_attributes" needs to be used instead of just "update"
    end
    
    # set UX variables
    @category = "cider"
    @beer_chosen = "complete"
    @cider_chosen = "current"
    @styles_chosen = 'current'
    
    # indicate this is coming from signup
    @create_drink_profile = true
    
    # get user delivery preferences
    @user_delivery_preference = DeliveryPreference.find_by_user_id(current_user.id)
    
    # get cider styles
    @styles_for_like = BeerStyle.where(signup_cider: true).order('style_order ASC')
    @cider_style_ids = @styles_for_like.pluck(:id)
    
    # find if user has already liked styles
    @all_user_styles = UserStylePreference.where(user_id: current_user.id)
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
       
  end # end of cider_styles method
  
  def wine_styles
    # remove session variables from previous step
    session.delete(:wine_timeframe)
    session.delete(:wine_number)
    
    # set getting started step
    @user = current_user
    if @user.getting_started_step < 5
      @user.update_attribute(:getting_started_step, 5) # because current_user is not an object, "update_attributes" needs to be used instead of just "update"
    end
    
    # get user delivery preferences
    @user_delivery_preference = DeliveryPreference.find_by_user_id(current_user.id)
    
    # set UX variables
    @category = "wine"
    @beer_chosen = "complete"
    @cider_chosen = "complete"
    @wine_chosen = "current"
    @styles_chosen = 'current'
    
  end # end of wine_styles method
  
  def process_styles
    # set referring page
    @referring_url = request.referrer
    
    # get data
    @data = params[:id]
    @split_data = @data.split("-")
    @preference = @split_data[0]
    @action = @split_data[1]
    @drink_style_id = @split_data[2].to_i
    
    # get all drinks styles
    @drink_styles = BeerStyle.all
    @style_info = @drink_styles.find_by_id(@drink_style_id)
    # find if chosen style is related to beer or cider
    if @style_info.signup_beer == true
      @beer_style = true
      @all_beer_style_ids = BeerStyle.where(signup_beer: true).pluck(:id)
    elsif @style_info.signup_cider == true
      @cider_style = true
      @all_cider_style_ids = BeerStyle.where(signup_cider: true).pluck(:id)
    end
    # get all related styles
    @style_id = @drink_styles.where(master_style_id: @drink_style_id).pluck(:id)    

    # adjust user liked/disliked styles
    if @action == "remove"
      @style_id.each do |style|
          if @beer_style
            @total_user_preferences = UserStylePreference.where(user_id: current_user.id, beer_style_id: @all_beer_style_ids)
          else
            @total_user_preferences = UserStylePreference.where(user_id: current_user.id, beer_style_id: @all_cider_style_ids)
          end
          @total_count = @total_user_preferences.count
          #Rails.logger.debug("Total Count: #{@total_count.inspect}")
          if @referring_url.include?("create_drink_profile") || @total_count > 1
            @user_style_preference = UserStylePreference.where(user_id: current_user.id, 
                                                              beer_style_id: style, 
                                                              user_preference: @preference)
            if !@user_style_preference.blank?
              @user_style_preference.delete_all
            end
            
            if @preference == "like"
              # check if any descriptors have been chosen
              @chosen_descriptors = UserDescriptorPreference.where(user_id: current_user.id,
                                                                beer_style_id: style)
              if !@chosen_descriptors.blank?
                @chosen_descriptors.delete_all
              end 
            end
         else
           @need_at_least_one_style = true
         end
      end
    end
    if @action == "add"
      @style_id.each do |style|
          @new_user_style_preference = UserStylePreference.create(user_id: current_user.id, 
                                                                    beer_style_id: style, 
                                                                    user_preference: @preference)
      end
    end # end of style each do loop
    
    # set last saved
    if !@referring_url.include?("create_drink_profile")
      if @new_user_style_preference.blank?
        @timing = @total_user_preferences.order('updated_at DESC')
        @last_saved = @timing.first.updated_at
      else
        @last_saved = @new_user_style_preference.updated_at
      end
    else 
      @last_saved = Time.now
    end
    
    respond_to do |format|
      format.js
    end
      
  end #end of process_styles method
  
  def process_chosen_descriptors
    # set referring page
    @referring_url = request.referrer
    
    # get data
    @data = params[:id]
    @split_data = @data.split("-")
    @action = @split_data[0]
    @drink_style_top_descriptor_id = @split_data[1].to_i
    
    #get descriptor info
    @descriptor_info = DrinkStyleTopDescriptor.find_by_id(@drink_style_top_descriptor_id)
    
    # get all related styles
    @styles = BeerStyle.where(master_style_id: @descriptor_info.beer_style.master_style_id).pluck(:id)
    #Rails.logger.debug("styles info: #{@styles.inspect}")
    # add descriptor for each related style
    @styles.each do |style_id|
      #Rails.logger.debug("style info: #{style_id.inspect}")
      if @action == "add"
        # add to user's descriptor prefrence
        @chosen_descriptor = UserDescriptorPreference.create(user_id: current_user.id,
                                                              beer_style_id: style_id,
                                                              tag_id: @descriptor_info.tag_id,
                                                              descriptor_name: @descriptor_info.descriptor_name)
      end
      if @action == "remove"
        UserDescriptorPreference.where(user_id: current_user.id,
                                                            beer_style_id: style_id,
                                                            descriptor_name: @descriptor_info.descriptor_name).destroy_all
        
      end
    end # end of loop through each related style
    
    if !@chosen_descriptor.blank?
      @last_saved = @chosen_descriptor.updated_at
    else
      @last_saved = Time.now
    end
  end # end of process_chosen_descriptors method
  
  #def beer_priorities
    # set getting started step
  #  @user = current_user
  #  if @user.getting_started_step < 4
  #    @user.update_attribute(:getting_started_step, 4) # because current_user is not an object, "update_attributes" needs to be used instead of just "update"
  #  end
    
    # set UX variables
  #  @category = "beer"
  #  @beer_chosen = "current"
  #  @journey_chosen = 'complete'
  #  @numbers_chosen = 'complete'
  #  @styles_chosen = 'complete'
  #  @priorities_chosen = 'current'
    
    # indicate this is coming from signup
  #  @create_drink_profile = true
    
    # get user delivery preferences
  #  @user_delivery_preference = DeliveryPreference.find_by_user_id(current_user.id)
    
    #@user_priorities = UserPriority.new
  #  @priorties = Priority.where(beer_relevant: true)
    
    #check if user has already chosen this question
  #  @priority_list = UserPriority.where(user_id: current_user.id, category: "beer")
  #  if !@priority_list.blank?
  #    @user_priorities = @priority_list.order('priority_rank ASC')
  #    @updated_order = @priority_list.order('updated_at DESC')
  #  end
    
  #  if !@user_priorities.blank?
  #    @priority_choice_header = "show"
  #    @chosen_priorities = @user_priorities.pluck(:priority_id)
  #  else
  #    @priority_choice_header = "hidden"
  #  end
  #end # end beer_priorities method
  
  #def cider_priorities
  #  # set getting started step
  #  @user = current_user
  #  if @user.getting_started_step < 9
  #    @user.update_attribute(:getting_started_step, 9) # because current_user is not an object, "update_attributes" needs to be used instead of just "update"
  #  end
    
    # set UX variables
  #  @category = "cider"
  #  @beer_chosen = "complete"
  #  @cider_chosen = "current"
  #  @journey_chosen = 'complete'
  #  @numbers_chosen = 'complete'
  #  @styles_chosen = 'complete'
  #  @priorities_chosen = 'current'
    
    # indicate this is coming from signup
  #  @create_drink_profile = true
    
    # get user delivery preferences
  #  @user_delivery_preference = DeliveryPreference.find_by_user_id(current_user.id)
    
    #@user_priorities = UserPriority.new
  #  @priorties = Priority.where(cider_relevant: true)
    
    #check if user has already chosen this question
  #  @priority_list = UserPriority.where(user_id: current_user.id, category: "cider")
  #  if !@priority_list.blank?
  #    @user_priorities = @priority_list.order('priority_rank ASC')
  #    @updated_order = @priority_list.order('updated_at DESC')
  #  end
    
  #  if !@user_priorities.blank?
  #    @priority_choice_header = "show"
  #    @chosen_priorities = @user_priorities.pluck(:priority_id)
  #  else
  #    @priority_choice_header = "hidden"
  #  end
  #end # end cider_priorities method
  
  def process_priority_questions
    # set referring page
    @referring_url = request.referrer
    
    # get data
    @data = params[:id]
    @split_data = @data.split("-")
    @category = @split_data[0]
    @priority_id = @split_data[1].to_i
    
    #check if user has already chosen any priorities
    @user_priorities = UserPriority.where(user_id: current_user.id, category: @category)
    
    if !@user_priorities.blank?
      # check if this priority is being selected or de-selected
      @this_priority = @user_priorities.find_by_priority_id(@priority_id)
      @priority_count = @user_priorities.count
      if @this_priority.blank?
        @new_count = @priority_count + 1
        # update total priorities of all other priorities
          @user_priorities.each do |priority|
              priority.update(total_priorities: @new_count)
          end
        # add this priority
        @action = "add"
        UserPriority.create(user_id: current_user.id, 
                            priority_id: @priority_id,
                            priority_rank: @new_count,
                            total_priorities: @new_count,
                            category: @category)
      else
        @this_priority_rank = @this_priority.priority_rank
        # remove this priority
        @action = "remove"
        @this_priority.destroy!
        if @priority_count > 1
          @new_count = @priority_count - 1
          # update ranks of those left behind, if needed
          @user_priorities.each do |priority|
            if priority.priority_rank > @this_priority_rank
              priority.decrement!(:priority_rank)
              priority.update(total_priorities: @new_count)
            end
          end
        end # end of count check
      end
    else # this path if this is the first priority chosen
      @action = "add"
      UserPriority.create(user_id: current_user.id, 
                            priority_id: @priority_id,
                            category: @category)
    end
    
    # get new list of chosen priorities
    @user_priorities = UserPriority.where(user_id: current_user.id, category: @category)
    @priority_count = @user_priorities.count
    #Rails.logger.debug("count: #{@priority_count.inspect}")
    @timing = @user_priorities.order('updated_at DESC')
    @last_saved = @timing.first.updated_at
    
    respond_to do |format|
      format.js
    end
  end # end of process_priority_questions method
  
  def rank_priority_questions
    @user_priorities = UserPriority.where(user_id: current_user.id)
  end # end rank_priority_questions method
  
  def process_rank_priority_questions
    # set referring page
    @referring_url = request.referrer
    
    # get data
    @info = params[:id]
    
    if @info == "data"
      @ranked_questions = params[:create_drink_profile].permit!.to_h
      @total_priorities = @ranked_questions["_json"].count
      #Rails.logger.debug("rank: #{@ranked_questions.inspect}")
      @ranked_questions["_json"].each do |rank|
        @data = rank
        @split_data = @data.split("-")
        @priority_id = @split_data[1]
        @priority_rank = @split_data[2]
        
        @user_priority = UserPriority.where(user_id: current_user.id, priority_id: @priority_id.to_i).first
        @user_priority.update(priority_rank: @priority_rank, total_priorities: @total_priorities)
      end
    end
    
    # get timing info
    @last_saved = @user_priority.updated_at
    
    respond_to do |format|
      format.js
    end

  end # end process_rank_priority_questions method
  
  def beer_costs 
    # set referring page
    @referring_url = request.referrer
    
    # set getting started step
    @user = current_user
    if @user.getting_started_step < 2
      @user.update_attribute(:getting_started_step, 2) # because current_user is not an object, "update_attributes" needs to be used instead of just "update"
    end
    
    # set UX variables
    @category = "beer"
    @beer_chosen = "current"
    @styles_chosen = 'complete'
    @costs_chosen = 'current'
    
    # indicate this is coming from signup
    @create_drink_profile = true
    
    # get user delivery preferences
    @user_delivery_preference = DeliveryPreference.find_by_user_id(current_user.id)
    
    # determine next step in drink profile creation
    if @user_delivery_preference.cider_chosen == true
      @next_step = drink_profile_cider_styles_path
    elsif @user_delivery_preference.wine_chosen == true
      @next_step = drink_profile_wine_styles_path
    else
      @next_step = process_final_drink_profile_step_path
    end
    
    # determine if beer price preferences exist
    @user_beer_preferences = UserPreferenceBeer.find_by_user_id(current_user.id)
    @last_saved = @user_beer_preferences.updated_at
    
    if !@user_beer_preferences.beer_price_estimate.nil?
      @drink_estimate = @user_beer_preferences.beer_price_estimate.round
    end
    #Rails.logger.debug("Estimate: #{@drink_estimate.inspect}")
  end # end of beer_costs method
  
  def cider_costs 
    # set referring page
    @referring_url = request.referrer
    
    # set getting started step
    @user = current_user
    if @user.getting_started_step < 4
      @user.update_attribute(:getting_started_step, 4) # because current_user is not an object, "update_attributes" needs to be used instead of just "update"
    end
    
    # set UX variables
    @category = "cider"
    @beer_chosen = "complete"
    @cider_chosen = "current"
    @styles_chosen = 'complete'
    @costs_chosen = 'current'
    
    # indicate this is coming from signup
    @create_drink_profile = true
    
    # get user delivery preferences
    @user_delivery_preference = DeliveryPreference.find_by_user_id(current_user.id)
    # determine next step in drink profile creation
    if @user_delivery_preference.wine_chosen == true
      @next_step = drink_profile_wine_styles_path
    else
      @next_step = process_final_drink_profile_step_path
    end
    
    # determine if cider price preferences exist
    @user_cider_preferences = UserPreferenceCider.find_by_user_id(current_user.id)
    @last_saved = @user_cider_preferences.updated_at
    
    if !@user_cider_preferences.cider_price_estimate.nil?
      @drink_estimate = @user_cider_preferences.cider_price_estimate.round
    end
    
  end # end of cider_costs method
  
  def process_drink_cost_estimates
    # set referring page
    @referring_url = request.referrer
    
    # get data
    @data = params[:id]
    @split_data = @data.split("-")
    @category = @split_data[0]
    @action = @split_data[1]
    @input = @split_data[2]
    
    # get user's category preferences
    @user_preferences = DeliveryPreference.find_by_user_id(current_user.id)
    
    if @category == "beer"
      @user_drink_preferences = UserPreferenceBeer.find_by_user_id(current_user.id)
      if @action == "average"
        @user_drink_preferences.update(beer_price_estimate: @input)
      end
      
      if @action == "limit"
        @user_drink_preferences.update(beer_price_limit: @input)
      end
      @price_response = @user_drink_preferences.beer_price_response
      @price_limit = @user_drink_preferences.beer_price_limit
    end
    
    if @category == "cider" 
      @user_drink_preferences = UserPreferenceCider.find_by_user_id(current_user.id)
      if @action == "average"
        @user_drink_preferences.update(cider_price_estimate: @input)
      end
      
      if @action == "limit"
        @user_drink_preferences.update(cider_price_limit: @input)
      end
      @price_response = @user_drink_preferences.cider_price_response
      @price_limit = @user_drink_preferences.cider_price_limit
    end
    
    # set last saved
    @last_saved = @user_drink_preferences.updated_at
    
    respond_to do |format|
      format.js
    end
    
  end # end of process_drink_cost_estimates method
  
  def corp_drink_details
  end
end # end of controller