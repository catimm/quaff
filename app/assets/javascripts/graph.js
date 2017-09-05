$.ajax({
           type: "GET",
           contentType: "application/json; charset=utf-8",
           url: 'reloads/data',
           dataType: 'json',
           success: function (data) {
               draw(data);
           },
           error: function (result) {
               error();
           }
       });
 
function draw(data) {
    var ourRatingGuess = 7.5;
    var userRating = 8.0;
    
    var tau = (2 * Math.PI);
    
    var dataCommonValue = 1;
	var baseBestGuessColor = 'rgba(255, 162, 0, 0.1)';
	var bestGuessColor = 'rgba(255, 162, 0, 1)';
	var baseUserRateColor = 'rgba(0, 135, 203, 0.1)';
	var userRateColor = 'rgba(0, 135, 203, 1)';
	var dataset = [{
	    value: dataCommonValue,
	    color: baseBestGuessColor,
	    label: '1'
	  }, {
	    value: dataCommonValue,
	    color: baseBestGuessColor,
	    label: '2'
	  }, {
	    value: dataCommonValue,
	    color: baseBestGuessColor,
	    label: '3'
	  }, {
	    value: dataCommonValue,
	    color: baseBestGuessColor,
	    label: '4'
	  }, {
	    value: dataCommonValue,
	    color: baseBestGuessColor,
	    label: '5'
	  }, {
	    value: dataCommonValue,
	    color: baseBestGuessColor,
	    label: '6'
	  }, {
	    value: dataCommonValue,
	    color: baseBestGuessColor,
	    label: '7'
	  }, {
	    value: dataCommonValue,
	    color: baseBestGuessColor,
	    label: '8'
	  }, {
	    value: dataCommonValue,
	    color: baseBestGuessColor,
	    label: '9'
	  }, {
	    value: dataCommonValue,
	    color: baseBestGuessColor,
	    label: '10'
	  }
	];
	
	var width = d3.select('#graph').node().offsetWidth,
	    height = 300,
	    cwidth = 33;
	
	var pie = d3.layout.pie()
	.sort(null)
	.value(function(d) {
	  return d.value;
	});
	
	// Create Best Guess Donut
	var bestGuessDonut = d3.svg.arc()
		.innerRadius(58)
		.outerRadius(cwidth * 2.85)
		.cornerRadius(4)
		.padAngle(.02);
	
	// Create Best Guess Arc
	var bestGuessArc = d3.svg.arc()
		.innerRadius(58)
		.outerRadius(cwidth * 2.85)
		.startAngle(0);
	
	// Create User Rating Donut	
	var userRatingDonut = d3.svg.arc()
		.innerRadius(65 + cwidth)
		.outerRadius(cwidth * 4)
		.cornerRadius(4)
		.padAngle(.02);
	
	// Create User Rating Arc
	var userRatingArc = d3.svg.arc()
		.innerRadius(65 + cwidth)
		.outerRadius(cwidth * 4)
		.startAngle(0);
	
	// Create canvas
	var svg = d3.select("#graph svg")
	.append("g")
	.attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");
	
	var gs = svg.selectAll("g").data(d3.values(dataset)).enter().append("g");
	
	var bestGuess = gs.selectAll("path")
	.data(function(d, i) {
	  return pie(d);
	})
	.enter();
	
	bestGuess.append("path")
	  .attr("fill", function(d) {
	  return baseB estGuessColor;
	})
	  .attr("d", innerArc(d));
	
	var userRating = gs.selectAll("path")
	.data(function(d, i) {
	  return pie(d);
	})
	.enter();
	
	userRating.append("path")
	  .attr("fill", function(d) {
	  return baseUserRateColor;
	})
	  .attr("d", outerArc(d));
	
	en.append("text")
	  .text(function(d) {
	    return d.data.label;
	  })
	  .style('fill', '#d9d9d9')
	  .attr("transform", function(d, i, j) {
	  return j === 0 ? "translate(" + innerArc.centroid(d) + ")" : "translate(" + outerArc.centroid(d) + ")";
	});
  
	// Add the User Rating foreground arc
	gs.append("path")
	    .style("fill", userRateColor)
	    .transition()
	    .duration(2000)
	    .delay(function(d, i) {
	      return i * 900;
	    })
		.attrTween('d', function(d) {
		   var i = d3.interpolate(0, ((userRating /  10) * tau));
		   return function(t) {
		       d.endAngle = i(t);
		     return foregroundOuterArc(d);
		   }
		})
	    .attr("id", "foregroundUserRating");
   
	var textUserRatingDescription = svg.append("text")
	    .attr("x", 6)
	    .attr("dy", 15);
	    
	textUserRatingDescription.append("textPath")
	    .attr("fill","#fff")
	    .attr("xlink:href","#foregroundUserRating")
	    .text("your rating...");
	
	// Add the Best Guess foreground arc
	var foregroundBestGuess = gs.append("path")
	    .style("fill", bestGuessColor)
	    .transition()
	    .duration(2000)
	    .delay(function(d, i) {
	      return i * 800;
	    })
		.attrTween('d', function(d) {
		   var i = d3.interpolate(0, ((ourRatingGuess /  10) * tau));
		   return function(t) {
		       d.endAngle = i(t);
		     return foregroundInnerArc(d);
		   }
		})
	    .attr("id", "foregroundBestGuess");
	
	var textBestGuess = svg.append("text")
	    .attr("x", 6)
	    .attr("dy", 15);
	    
	textBestGuess.append("textPath")
	    .attr("fill","#fff")
	    .attr("xlink:href","#foregroundBestGuess")
	    .text("our guess for you...");
	    
	// Knird Guess middle text
    gs.append("text")
	  	.attr("x", -45)
	    .attr("y", -5) 
	    .text("Our guess: " + ourRatingGuess)
	    .style("fill", bestGuessColor);
	
	// Knird Guess middle text
    gs.append("text")
	  	.attr("x", -45)
	    .attr("y", 15) 
	    .text("Your rating: " + userRating)
	    .style("fill", userRateColor);
	
}
function error() {
    console.log("error");
};