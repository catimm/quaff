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

});