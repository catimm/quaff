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
    @large_cooler_cost = 9
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
    
    # determine drink numbers for each category
    @number_of_large_cellar = (@drink_per_delivery_calculation * @cellar_percentage * @large_percentage)
    @number_of_small_cellar = (@drink_per_delivery_calculation * @cellar_percentage * (1 - @large_percentage))
    @number_of_large_cooler = (@drink_per_delivery_calculation * (1 - @cellar_percentage) * @large_percentage)
    @number_of_small_cooler = (@drink_per_delivery_calculation * (1 - @cellar_percentage) * (1 - @large_percentage))
    
    # multiply drink numbers by drink costs
    @cost_estimate_cooler_small = (@small_cooler_cost * @number_of_small_cooler)
    @cost_estimate_cooler_large = (@large_cooler_cost * @number_of_large_cooler)
    @cost_estimate_cellar_small = (@small_cellar_cost * @number_of_small_cellar)
    @cost_estimate_cellar_large = (@large_cellar_cost * @number_of_large_cellar)
    @total_cost_estimate = (@cost_estimate_cooler_small + @cost_estimate_cooler_large + @cost_estimate_cellar_small + @cost_estimate_cellar_large).round
  
    # update delivery prefrence drink total estimation
    @delivery_preferences.update(price_estimate: @total_cost_estimate)
    
  end # end delivery_estimator method

end