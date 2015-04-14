$(function() {
	$('.chosen-select').chosen({
		allow_single_deselect: true,
		no_results_text: "No results matched",
		width: "90%",
		placeholder_text_multiple: "Filter by one or more",
		placeholder_text_single: "Filter by one"
	});
});
