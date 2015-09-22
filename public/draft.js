window.onload = function() {

   //Params
   var scriptPram = document.getElementById('load_widget');
   var id = scriptPram.getAttribute('data-page');

   //iFrame
   var iframe = document.createElement('iframe');
   iframe.name = "draft-frame";
   iframe.style.border = "0";
   iframe.style.frameborder = "0";
   iframe.style.cellspacing = "0";
   iframe.style.width = "100%";
   iframe.src = "https://quaff-stage.herokuapp.com/draft/" + id;
   document.body.appendChild(iframe);
   
   //css
   var cssLink = document.createElement("link");
   cssLink.href = "/assets/application-15d9bb5a37036843a6caa5de5da2b0e6.css";
   cssLink .rel = "stylesheet";
   cssLink .type = "text/css";
   frames['draft-frame'].document.head.appendChild(cssLink);
};