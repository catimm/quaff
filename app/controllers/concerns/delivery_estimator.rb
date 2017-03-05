module DeliveryEstimator
  extend ActiveSupport::Concern
  
  def delivery_estimator(customer_id, drinks_per_week, large_format, status)
    # get customer info
    @customer_info = User.find_by_id(customer_id)
    @customer_sophistication = @customer_info.craft_stage_id
    
    # get customer delivery preferences
    @delivery_preferences = DeliveryPreference.find_by_user_id(customer_id)
    
    #determine drinks per delivery
    @drink_per_delivery_calculation = (drinks_per_week * 2.2).round
    #Rails.logger.debug("Drinks per delivery: #{@drink_per_delivery_calculation.inspect}") 
    
    # determine large format percentage
    @large_percentage = ((large_format.to_f) / (drinks_per_week.to_f)).round(3)
    
    # determine # of large and small format drinks
    @large_format_number = large_format
    #Rails.logger.debug("Large Format #: #{@large_format_number.inspect}")
    @small_format_number = @drink_per_delivery_calculation - (@large_format_number * 2) # this counts each large format as 2 small format drinks
    #Rails.logger.debug("Small Format #: #{@small_format_number.inspect}")
     
    # determine percentage of cellar/cooler drinks per delivery
    if @customer_sophistication == 1
      @cellar_percentage = 0.05
      @cooler_percentage = 0.95
    elsif @customer_sophistication == 2
      @cellar_percentage = 0.075
      @cooler_percentage = 0.925
    else
      @cellar_percentage = 0.1
      @cooler_percentage = 0.9
    end
    
    # determine max number of cellar drinks per delivery
    @max_cellar = (@drink_per_delivery_calculation * @cellar_percentage).round

    # determine number of large/small cellar/cooler drinks
    @number_of_large_cellar = (@large_format_number * @cellar_percentage)  
    @number_of_small_cellar = (@small_format_number * @cellar_percentage)
    @number_of_large_cooler = (@large_format_number * @cooler_percentage)
    @number_of_small_cooler = (@small_format_number * @cooler_percentage)
    #Rails.logger.debug("# large cellar: #{@number_of_large_cellar.inspect}") 
    #Rails.logger.debug("# small cellar: #{@number_of_small_cellar.inspect}") 
    #Rails.logger.debug("# large cooler: #{@number_of_large_cooler.inspect}")
    #Rails.logger.debug("# small cooler: #{@number_of_small_cooler.inspect}") 
    
    # get all drinks in inventory
    @inventory = Inventory.all
    @inventory_small_cooler = @inventory.small_cooler_drinks
    @inventory_small_cellar = @inventory.small_cellar_drinks
    @inventory_large_cooler = @inventory.large_cooler_drinks
    @inventory_large_cellar = @inventory.large_cellar_drinks
    
    # first set average drink costs
    if !@inventory_small_cooler.nil?
      @small_cooler_cost = (@inventory_small_cooler.average(:drink_price)).to_f
      if @small_cooler_cost == 0
        @small_cooler_cost = 3
      end
    else
      @small_cooler_cost = 3
    end
    if !@inventory_small_cellar.nil?
      @large_cooler_cost = (@inventory_small_cellar.average(:drink_price)).to_f
      if @large_cooler_cost == 0
        @large_cooler_cost = 6
      end
    else
      @large_cooler_cost = 6
    end
    if !@inventory_large_cooler.nil?
      @small_cellar_cost = (@inventory_large_cooler.average(:drink_price)).to_f
      if @small_cellar_cost == 0
        @small_cellar_cost = 13
      end
    else
      @small_cellar_cost = 13
    end
    if !@inventory_large_cellar.nil?
      @large_cellar_cost = (@inventory_large_cellar.average(:drink_price)).to_f
      if @large_cellar_cost == 0
        @large_cellar_cost = 18
      end
    else
      @large_cellar_cost = 18
    end
    #Rails.logger.debug("Small cooler cost: #{@small_cooler_cost.inspect}")
    #Rails.logger.debug("Small cellar cost: #{@large_cooler_cost.inspect}")
    #Rails.logger.debug("Large cooler cost: #{@small_cellar_cost.inspect}")
    #Rails.logger.debug("Large cellar cost: #{@large_cellar_cost.inspect}")
   
    
    # multiply drink numbers by drink costs
    @cost_estimate_cooler_small = (@small_cooler_cost * @number_of_small_cooler)  
    @cost_estimate_cooler_large = (@large_cooler_cost * @number_of_large_cooler) 
    @cost_estimate_cellar_small = (@small_cellar_cost * @number_of_small_cellar)
    @cost_estimate_cellar_large = (@large_cellar_cost * @number_of_large_cellar)
    #Rails.logger.debug("$ small cooler: #{@cost_estimate_cooler_small.inspect}") 
    #Rails.logger.debug("$ large cooler: #{@cost_estimate_cooler_large.inspect}")
    #Rails.logger.debug("$ small cellar: #{@cost_estimate_cellar_small.inspect}")
    #Rails.logger.debug("$ large cellar: #{@cost_estimate_cellar_large.inspect}") 
    
    @total_cost_estimate = (@cost_estimate_cooler_small + @cost_estimate_cooler_large + @cost_estimate_cellar_small + @cost_estimate_cellar_large).round
    #Rails.logger.debug("Total $: #{@total_cost_estimate.inspect}") 
  
    # update delivery prefrence drink total estimation
    if status == "update"
      @delivery_preferences.update(price_estimate: @total_cost_estimate, max_cellar: @max_cellar)
    else
      @delivery_preferences.temp_cost_estimate = @total_cost_estimate
    end
    
  end # end delivery_estimator method

end