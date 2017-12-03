module QuerySearch
  extend ActiveSupport::Concern
  def query_search(search_term, only_ids)
      @search = Beer.search body: {
  "query": {
    "bool": {
      "should": [
        { "match": { "short_brewery_name": { "query": "#{search_term}", "operator": "or", "boost": 12 } }},
        { "match": { "brewery_name": { "query": "#{search_term}", "operator": "or", "boost": 8 } }},
        { "match": { "beer_name": { "query": "#{search_term}", "operator": "or", "boost": 20 } }},
        { "match": { "short_brewery_name_special": { "query": "#{search_term}", "fuzziness": "AUTO", "operator": "or", "boost": 1 } }},
        { "match": { "brewery_name_special": { "query": "#{search_term}", "fuzziness": "AUTO", "operator": "or", "boost": 1 } }},
        { "match": { "beer_name_special": { "query": "#{search_term}", "fuzziness": "AUTO", "operator": "or", "boost": 4 } }}
      ]
    }
  }
}

      search_results = @search.response["hits"]["hits"]
      search_result_ids = search_results.map{ |result| result["_id"].to_i }

      if only_ids == true
        @final_search_results = search_result_ids
      else
        search_result_beers = Beer.where(id: search_result_ids)
        @final_search_results = search_result_beers.index_by(&:id).values_at(*search_result_ids)
      end
      
      Rails.logger.debug("======================== Search results in order before returning = : #{@final_search_results.inspect}")
  end
end
