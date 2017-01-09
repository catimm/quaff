class CreateBeerTempTable < ActiveRecord::Migration
  ActiveRecord::Base.connection.execute("CREATE TABLE beers_temp (LIKE beers INCLUDING DEFAULTS INCLUDING INDEXES);")
end
