

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
	                   	abv: beer.abv,
	                   	form: beer.form,
	                   	use: beer.use
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
	          limit: 7,
	          displayKey: 'beer',
	          source: numbers.ttAdapter(),
	          templates: {
				    empty: function() {
				    	if(window.location.href.indexOf("draft_boards") > -1) {
				    		return ['<div class="empty-message"><a data-toggle="modal" data-target="#add_drink" href="/draft_boards/new_drink">',
					        'Not here? Click here to add it.','</a></div>'].join('\n');
				    	} else if(window.location.href.indexOf("draft_inventory") > -1) {
				    		return ['<div class="empty-message"><a data-toggle="modal" data-target="#add_drink" href="/draft_inventory/new_drink">',
					        'Not here? Click here to add it.','</a></div>'].join('\n');
				    	} else {
					      	return ['<div class="empty-message"><a href="'+ BASE_URL +'searches/add_beer">',
					        'Not here? Click here to suggest we add it!','</a></div>'].join('\n');
					    }
				     },
				    suggestion: function(data) {
					    if(data.source == "retailer" || data.source == "retailer") {
					    	return '<p>' + data.beer +'</p>';    	
						} else {
							return '<p><a href="'+ BASE_URL +'breweries/'+ data.brewery_id +'/beers/'+ data.beer_id +'">' + data.beer + '</a></p>';
						}
					},
					footer: function() {
						if(window.location.href.indexOf("draft_boards") > -1) {
				    		return ['<div class="search-footer-message">Not here? <a data-toggle="modal" data-target="#add_drink" href="/draft_boards/new_drink" class="btn btn-default btn-success formButton-search-footer">',
					        'Add it.','</a></div>'].join('\n');
				    	} else if(window.location.href.indexOf("draft_inventory") > -1) {
				    		return ['<div class="search-footer-message">Not here? <a data-toggle="modal" data-target="#add_drink" href="/draft_inventory/new_drink" class="btn btn-default btn-success formButton-search-footer">',
					        'Add it.','</a></div>'].join('\n');
				    	}
					}
				}
	        }).on('typeahead:selected', function (obj, datum) {   
			    if(datum.source == "retailer") {
					//console.log(datum);
					if (datum.use == "draft_inventory"){
						$.ajax({
					        url : "/draft_inventory/edit",
					        type : "get",
					        data : { chosen_drink: JSON.stringify(datum) }
					    });
					} else {
						if(datum.form == "edit") {
							$.ajax({
						        url : "/draft_boards/edit",
						        type : "get",
						        data : { chosen_drink: JSON.stringify(datum) }
						    });
						} else {
							$.ajax({
						        url : "/draft_boards/new",
						        type : "get",
						        data : { chosen_drink: JSON.stringify(datum) }
						    });
						}
					} 	
				}
	    	});
};
$(document).on('nested:fieldAdded', function(event){
	$('.typeahead').typeahead('destroy');
	ready();
});


$(document).ready(ready);
$(document).on('page:load', ready);