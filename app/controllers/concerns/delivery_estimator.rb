module DeliveryEstimator
  extend ActiveSupport::Concern
  
  def delivery_estimator(customer_id)
    # get customer info
    @customer_info = User.find(customer_id)
    @customer_sophistication = @customer_info.craft_stage_id
    
    # get customer delivery preferences
    @delivery_preferences = DeliveryPreference.where(user_id: customer_id).first
    @drink_per_delivery_calculation = (@delivery_preferences.drinks_per_week * 2.2).round
    
    # determine large format percentage
    @large_percentage = (@delivery_preferences.max_large_format) / (@delivery_preferences.drinks_per_week).round(3)
    
    # first set average drink costs
    @small_cooler_cost = 3
    @large_cooler_cost = 6
    @small_cellar_cost = 13
    @large_cellar_cost = 18
    
    # determine number of cellar drinks per delivery
    if @customer_sophistication == 1
      @cellar_percentage = 0.05
    elsif @customer_sophistication == 2
      @cellar_percentage = 0.075
    else
      @cellar_percentage = 0.1
    end
    
    # determine max number of cellar drinks per delivery
    @max_cellar = (@drink_per_delivery_calculation * @cellar_percentage).ceil
    
    # determine drink numbers for each category
    @number_of_large_cellar = (@drink_per_delivery_calculation * @cellar_percentage * @large_percentage) #0
    Rails.logger.debug("# large cellar: #{@number_of_large_cellar.inspect}") 
    @number_of_small_cellar = (@drink_per_delivery_calculation * @cellar_percentage * (1 - @large_percentage))
    Rails.logger.debug("# small cellar: #{@number_of_small_cellar.inspect}") 
    @number_of_large_cooler = (@drink_per_delivery_calculation * (1 - @cellar_percentage) * @large_percentage)
    Rails.logger.debug("# large cooler: #{@number_of_large_cooler.inspect}") 
    @number_of_small_cooler = (@drink_per_delivery_calculation * (1 - @cellar_percentage) * (1 - @large_percentage))
    Rails.logger.debug("# small cooler: #{@number_of_small_cooler.inspect}") 
    
    # multiply drink numbers by drink costs
    @cost_estimate_cooler_small = (@small_cooler_cost * @number_of_small_cooler)
    Rails.logger.debug("$ small cooler: #{@cost_estimate_cooler_small.inspect}") 
    @cost_estimate_cooler_large = (@large_cooler_cost * @number_of_large_cooler)
    Rails.logger.debug("$ large cooler: #{@cost_estimate_cooler_large.inspect}") 
    @cost_estimate_cellar_small = (@small_cellar_cost * @number_of_small_cellar)
    Rails.logger.debug("$ small cellar: #{@cost_estimate_cellar_small.inspect}") 
    @cost_estimate_cellar_large = (@large_cellar_cost * @number_of_large_cellar)
    Rails.logger.debug("$ large cellar: #{@cost_estimate_cellar_large.inspect}") 
    @total_cost_estimate = (@cost_estimate_cooler_small + @cost_estimate_cooler_large + @cost_estimate_cellar_small + @cost_estimate_cellar_large).round
  
    # update delivery prefrence drink total estimation
    @delivery_preferences.update(price_estimate: @total_cost_estimate, max_cellar: @max_cellar)
    
  end # end delivery_estimator method

end