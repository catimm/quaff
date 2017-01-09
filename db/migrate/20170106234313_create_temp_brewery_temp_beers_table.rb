class CreateTempBreweryTempBeersTable < ActiveRecord::Migration
  ActiveRecord::Base.connection.execute("CREATE TABLE temp_breweries_temp_beers (LIKE beers INCLUDING DEFAULTS INCLUDING INDEXES);")
end
