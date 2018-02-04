module DeliveryEstimator
  extend ActiveSupport::Concern

  def estimate_drinks(number_of_drinks, max_large_format, craft_stage)

    # determine large format percentage
    @large_percentage = (max_large_format.to_f / number_of_drinks.to_f).round(3)

    # of large format drinks
    @large_format_number = max_large_format

    # determine small format number by counting each large format as 2 small format drinks
    @small_format_number = number_of_drinks - (@large_format_number * 2)

    # determine percentage of cellar/cooler drinks per delivery
    if craft_stage == 1
      @cellar_percentage = 0.05
      @cooler_percentage = 0.95
    elsif craft_stage == 2
      @cellar_percentage = 0.075
      @cooler_percentage = 0.925
    else
      @cellar_percentage = 0.1
      @cooler_percentage = 0.9
    end

    # determine max number of cellar drinks per delivery
    @max_cellar = (number_of_drinks * @cellar_percentage).round

    # determine number of large/small cellar/cooler drinks
    @number_of_large_cellar = (@large_format_number * @cellar_percentage).round  
    @number_of_small_cellar = (@small_format_number * @cellar_percentage).round
    @number_of_large_cooler = (@large_format_number * @cooler_percentage).round
    @number_of_small_cooler = (@small_format_number * @cooler_percentage).round 
    
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
    
    # multiply drink numbers by drink costs
    @cost_estimate_cooler_small = (@small_cooler_cost * @number_of_small_cooler)  
    @cost_estimate_cooler_large = (@large_cooler_cost * @number_of_large_cooler) 
    @cost_estimate_cellar_small = (@small_cellar_cost * @number_of_small_cellar)
    @cost_estimate_cellar_large = (@large_cellar_cost * @number_of_large_cellar)
    
    @total_cost_estimate = (@cost_estimate_cooler_small + @cost_estimate_cooler_large + @cost_estimate_cellar_small + @cost_estimate_cellar_large).round
    return @total_cost_estimate
  end
  
  
  def delivery_estimator(delivery_preferences, craft_stage)

    @total_cost_estimate = estimate_drinks(delivery_preferences.drinks_per_delivery, delivery_preferences.max_large_format, craft_stage)
  
    # update delivery preferences
    DeliveryPreference.update(delivery_preferences.id, price_estimate: @total_cost_estimate, max_cellar: @max_cellar)
    
  end # end delivery_estimator method

end