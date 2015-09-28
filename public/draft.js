window.onload = function() {

   //Params
   var scriptPram = document.getElementById('load_widget');
   var id = scriptPram.getAttribute('data-page');
	
	
   
   //iFrame
   var iframe = document.createElement('iframe');
   iframe.name = "draft-frame";
   iframe.id = "draft-frame";
   iframe.style.border = "0";
   iframe.style.frameborder = "0";
   iframe.style.cellspacing = "0";
   iframe.style.width = "100%";
   iframe.scrolling = "no";
   iframe.src = "https://quaff-stage.herokuapp.com/draft/" + id;
   document.body.appendChild(iframe);

	//jquery
	var jquery = document.createElement('script');
	jquery.type = "text/javascript";
   	jquery.src = "https://ajax.googleapis.com/ajax/libs/jquery/2.1.3/jquery.min.js";
   	document.body.appendChild(jquery);
   	
   //resizing iFrame
   var iframe_script_one = document.createElement('script');
   iframe_script_one.type = "text/javascript";
   iframe_script_one.src = "https://quaff-stage.herokuapp.com/iframeResizer.min.js";
   document.body.appendChild(iframe_script_one);
   var iframe_script_two = document.createElement('script');
   iframe_script_two.type = "text/javascript";
   iframe_script_two.innerHTML = "$( document ).ready(function() { iFrameResize({log:true}); });";
   document.body.appendChild(iframe_script_two);
   
   //css
   //var cssLink = document.createElement('link');
   //cssLink.href = "https://quaff-stage.herokuapp.com/bootstrap-custom.css.scss";
   //cssLink.rel = "stylesheet";
   //cssLink.type = "text/css";
   //var ifrm = document.getElementById('draft-frame');
   //ifrm.contentWindow.document.head.appendChild(cssLink);
   //$('#draft-frame').contents().find('head').append('<link href="https://quaff-stage.herokuapp.com/bootstrap-custom.css.scss" rel="stylesheet" type="text/css">');

};