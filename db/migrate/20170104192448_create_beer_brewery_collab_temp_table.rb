class CreateBeerBreweryCollabTempTable < ActiveRecord::Migration
  ActiveRecord::Base.connection.execute("CREATE TABLE beer_brewery_collabs_temp (LIKE beer_brewery_collabs INCLUDING DEFAULTS INCLUDING INDEXES);")
end
