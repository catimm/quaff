module TypeBasedGuess
  extend ActiveSupport::Concern
  
  def type_based_guess(this_beer)
    this_beer.best_guess = 8
  end # end of method
end # end of module