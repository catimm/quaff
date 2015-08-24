

var ready;
ready = function() {
    var numbers = new Bloodhound({
      datumTokenizer: function (datum) {
        return Bloodhound.tokenizers.whitespace(datum.beer, datum.brewery);
    	},
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        remote: { 
        	url:'/breweries/autocomplete?query=%QUERY',
        	wildcard: '%QUERY',
			filter: function (beers) {
	            console.log(beers);
	            // $.map converts the JSON array into a JavaScript array
	            return $.map(beers, function (beer) {
	                return {
	                    beer: beer.beer_name,
	                    beer_id: beer.beer_id,
	                    brewery: beer.brewery_name,
	                    brewery_id: beer.brewery_id
	                };
	            });
	       }
        }
	 });
     // initialize the bloodhound suggestion engine

     var promise = numbers.initialize();
     promise
      .done(function() { console.log('success!'); })
      .fail(function() { console.log('err!'); });
     
     // instantiate the typeahead UI
        $('.typeahead').typeahead({   
          hint: true,
		  highlight: true,
		  minLength: 1
		  },
		  {
		  name: 'beer',
          displayKey: 'beer',
          source: numbers.ttAdapter(),
          templates: {
			    empty: [
			      '<div class="empty-message"><a href="http://localhost:3000/searches/add_beer">',
			        'Not found. Click here to suggest we add it!',
			      '</a></div>'
			    ].join('\n'),
			    suggestion: function(data) {
				    return '<p><a href="http://'+ BASE_URL +'/breweries/'+ data.brewery_id +'/beers/'+ data.beer_id +'">' + data.brewery + ' ' + data.beer + '</a></p>';
				}
			}
        });
};

$(document).ready(ready);
$(document).on('page:load', ready);

alert(BASE_URL);
