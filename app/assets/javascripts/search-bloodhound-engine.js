

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
	            //console.log(beers);
	            // $.map converts the JSON array into a JavaScript array
	            return $.map(beers, function (beer) {
	                return {
	                    beer: beer.brewery_name + ' ' + beer.beer_name,
	                    beer_id: beer.beer_id,
	                    brewery: beer.brewery_name,
	                    brewery_id: beer.brewery_id,
	                    source: beer.source,
	                    type: beer.type,
	                   	ibu: beer.ibu,
	                   	abv: beer.abv
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
				      '<div class="empty-message"><a href="'+ BASE_URL +'searches/add_beer">',
				        'Not found. Click here to suggest we add it!',
				      '</a></div>'
				    ].join('\n'),
				    suggestion: function(data) {
					    if(data.source == "retailer") {
					    	return '<p>' + data.beer +'</p>';	    	
						} else {
							return '<p><a href="'+ BASE_URL +'breweries/'+ data.brewery_id +'/beers/'+ data.beer_id +'">' + data.beer + '</a></p>';
						}
					}
				}
	        }).on('typeahead:selected', function (obj, datum) {   
			    if(datum.source == "retailer") {
					//console.log(datum);
					$.ajax({
				        url : "/draft_boards/edit",
				        type : "get",
				        data : { chosen_drink: JSON.stringify(datum) }
				    });	    	
				}
	    	});
};
$(document).on('nested:fieldAdded', function(event){
	$('.typeahead').typeahead('destroy');
	ready();
});


$(document).ready(ready);
$(document).on('page:load', ready);