$(function () {
	// show user profile block when this link is clicked, if it isn't already showing
	$("#user-profile-link").on("click", function() {
		if ($("#user-profile").hasClass("hidden")) {
			$("#user-profile").removeClass("hidden").addClass("show");
			$("#user-notifications").removeClass("show").addClass("hidden");
			$("#user-profile-link").addClass("selected");
			$("#user-notifications-link").removeClass("selected");
		}
	});
	// if this link isn't already active, show underline when mouse over
	$("#user-profile-link").on("mouseover", function() {
		if ($("#user-profile").hasClass("hidden")) {
			$(this).css("text-decoration", "underline");
		}
	});
	// remove underline when mouse out	
	$("#user-profile-link").on("mouseout", function() {
		$(this).css("text-decoration", "none");
	});
	// show user profile block when this link is clicked, if it isn't already showing
	$("#user-notifications-link").on("click", function() {
		if ($("#user-notifications").hasClass("hidden")) {
			$("#user-notifications").removeClass("hidden").addClass("show");
			$("#user-profile").removeClass("show").addClass("hidden");
			$("#user-notifications-link").addClass("selected");
			$("#user-profile-link").removeClass("selected");
		}
	});
	// if this link isn't already active, show underline when mouse over
	$("#user-notifications-link").on("mouseover", function() {
		if ($("#user-notifications").hasClass("hidden")) {
			$(this).css("text-decoration", "underline");
		}
	});	
	// remove underline when mouse out
	$("#user-notifications-link").on("mouseout", function() {
		$(this).css("text-decoration", "none");
	});
	
	// show and hide password change form
	$("#change-password-button").on("click", function() {
		if ($(".password-change-form").hasClass("hidden")) {
			$(".password-change-form").removeClass("hidden").addClass("show");
		} else {
			$(".password-change-form").removeClass("show").addClass("hidden");
		}
	});
	
	// show user profile block when this link is clicked, if it isn't already showing
	$("#user-styles-link").on("click", function() {
		if ($("#user-styles").hasClass("hidden")) {
			$("#user-styles").removeClass("hidden").addClass("show");
			$("#user-drinks").removeClass("show").addClass("hidden");
			$("#user-styles-link").addClass("selected");
			$("#user-drinks-link").removeClass("selected");
		}
	});
	// if this link isn't already active, show underline when mouse over
	$("#user-styles-link").on("mouseover", function() {
		if ($("#user-styles").hasClass("hidden")) {
			$(this).css("text-decoration", "underline");
		}
	});
	// remove underline when mouse out	
	$("#user-styles-link").on("mouseout", function() {
		$(this).css("text-decoration", "none");
	});
	// show user profile block when this link is clicked, if it isn't already showing
	$("#user-drinks-link").on("click", function() {
		if ($("#user-drinks").hasClass("hidden")) {
			$("#user-drinks").removeClass("hidden").addClass("show");
			$("#user-styles").removeClass("show").addClass("hidden");
			$("#user-drinks-link").addClass("selected");
			$("#user-styles-link").removeClass("selected");
		}
	});
	// if this link isn't already active, show underline when mouse over
	$("#user-drinks-link").on("mouseover", function() {
		if ($("#user-drinks").hasClass("hidden")) {
			$(this).css("text-decoration", "underline");
		}
	});	
	// remove underline when mouse out
	$("#user-drinks-link").on("mouseout", function() {
		$(this).css("text-decoration", "none");
	});

	// allow user to dislike beer style
	$(".dislike-style").on("click", function() {
		if ($(this).siblings(".dislike-style-chosen").hasClass("hidden")) {
			// change view/UI
			$(this).removeClass("show").addClass("hidden");
			$(this).siblings(".dislike-style-chosen").removeClass("hidden").addClass("show");
			// add overlay
			$(this).siblings(".overview-tile-4").addClass("show").removeClass("hidden");
			// if like is already chosen, reverse it
			if ($(this).siblings(".like-style-chosen").hasClass("show")) {
				$(this).siblings(".like-style-chosen").removeClass("show").addClass("hidden");	
			}
			if ($(this).siblings(".like-style").hasClass("hidden")) {
				$(this).siblings(".like-style").removeClass("hidden").addClass("show");
			}
			// change user preference form value
			$(this).parent(".overview-tile-3").siblings("#styles__user_preference").val(1);
		}
	});
	// allow user to reverse dislike of beer style
	$(".dislike-style-chosen").on("click", function() {
		if ($(this).hasClass("show")) {
			$(this).removeClass("show").addClass("hidden");
			$(this).siblings(".dislike-style").removeClass("hidden").addClass("show");
			// remove overlay
			$(this).siblings(".overview-tile-4").removeClass("show").addClass("hidden");
		}
		// change user preference form value
		$(this).parent(".overview-tile-3").siblings("#styles__user_preference").val(0);
	});
	
	// allow user to like beer style
	$(".like-style").on("click", function() {
		if ($(this).siblings(".like-style-chosen").hasClass("hidden")) {
			$(this).removeClass("show").addClass("hidden");
			$(this).siblings(".like-style-chosen").removeClass("hidden").addClass("show");
			// add overlay
			$(this).siblings(".overview-tile-4").addClass("show").removeClass("hidden");
			// if dislike is already chosen, reverse it
			if ($(this).siblings(".dislike-style-chosen").hasClass("show")) {
				$(this).siblings(".dislike-style-chosen").removeClass("show").addClass("hidden");
			}
			if ($(this).siblings(".dislike-style").hasClass("hidden")) {
				$(this).siblings(".dislike-style").removeClass("hidden").addClass("show");
			}
			// change user preference form value
			$(this).parent(".overview-tile-3").siblings("#styles__user_preference").val(2);
		}
	});
	// allow user to reverse like of beer style
	$(".like-style-chosen").on("click", function() {
		if ($(this).hasClass("show")) {
			$(this).removeClass("show").addClass("hidden");
			$(this).siblings(".like-style").removeClass("hidden").addClass("show");
			// remove overlay
			$(this).siblings(".overview-tile-4").removeClass("show").addClass("hidden");
		}
		// change user preference form value
		$(this).parent(".overview-tile-3").siblings("#styles__user_preference").val(0);
	});
	
	// find width of style preference overview tile
	style_width = $(".overview-tile-3").width();
	half_style_width = style_width/2;
	// make width of selected style overlay equal that of the overview tile
	$(".overview-tile-4").width(style_width);
	// make width of style preference row equal that of the overview tile
	$(".like-style-chosen").width(style_width);
	$(".dislike-style-chosen").width(style_width);
	// make chosen preference appear in middle of tile regardless of tile size
	$(".dislike-style-chosen").children(".dislike-style-middle").css("left",style_width - half_style_width - 18);
	$(".like-style-chosen").children(".like-style-middle").css("left",style_width - half_style_width - 18);
	
	// find width of style preference overview tile for mobile
	mobile_style_width = $(".row-horizon").children(".mobile.style-tile-container").width();
	half_style_width = mobile_style_width/2;
	// make width of selected style overlay equal that of the overview tile
	$(".mobile.overview-tile-4").width(mobile_style_width);
	// make width of style preference row equal that of the overview tile
	$(".mobile.like-style-chosen").width(mobile_style_width);
	$(".mobile.dislike-style-chosen").width(mobile_style_width);
	// make chosen preference appear in middle of tile regardless of tile size
	$(".mobile.dislike-style-chosen").children(".mobile.dislike-style-middle").css("left",mobile_style_width - half_style_width - 18);
	$(".mobile.like-style-chosen").children(".mobile.like-style-middle").css("left",mobile_style_width - half_style_width - 18);
	
	// find width of the navbar search input box
	navbar_search_width = $("#header-navbar").children(".input-group").width() + 20;
	// make the dropdown search result box match the width of the search input box
	$(".tt-menu").width(navbar_search_width);
});