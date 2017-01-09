class CreateBreweryTempTable < ActiveRecord::Migration
    ActiveRecord::Base.connection.execute("CREATE TABLE breweries_temp (LIKE breweries INCLUDING DEFAULTS INCLUDING INDEXES);")
end
