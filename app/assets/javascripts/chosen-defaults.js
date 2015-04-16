$(function() {
	$('.chosen-select').chosen({
		allow_single_deselect: true,
		no_results_text: "No results matched",
		width: "90%",
		placeholder_text_multiple: "Choose one or more",
		placeholder_text_single: "Choose only one"
	});
});
