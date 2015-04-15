$(function () {
	function change_add_drink_button() {
		 $(this).children("i").removeClass("fa-plus-square-o").addClass("fa-minus-square-o");
		 $(this).removeClass("btn-info").removeClass("add-drink-button").addClass("btn-default").addClass("remove-drink-button");	
		
	}
	function change_remove_drink_button() {
		$(this).children("i").removeClass("fa-minus-square-o").addClass("fa-plus-square-o");
		$(this).removeClass("btn-default").removeClass("remove-drink-button").addClass("btn-info").addClass("add-drink-button");
	}
	$(function() {
	  return $(document).on('click', '.add-drink-button', change_add_drink_button);
	});
	$(function() {
	  return $(document).on('click', '.remove-drink-button', change_remove_drink_button);
	});

	$(".more-info").on("click", function() {
			$(this).removeClass("show").addClass("hidden");
			$(this).parent(".beer-info").children(".less-info").removeClass("hidden").addClass("show");
			$(this).parent(".beer-info").siblings(".descriptor-row").removeClass("hidden").addClass("show");
	});
	$(".less-info").on("click", function() {
			$(this).removeClass("show").addClass("hidden");
			$(this).parent(".beer-info").children(".more-info").removeClass("hidden").addClass("show");
			$(this).parent(".beer-info").siblings(".descriptor-row").removeClass("show").addClass("hidden");
	});
});