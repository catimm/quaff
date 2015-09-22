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
   iframe.style.height = "100%";
   iframe.src = "https://quaff-stage.herokuapp.com/draft/" + id;
   document.body.appendChild(iframe);

   //css
   var cssLink = document.createElement('link');
   cssLink.href = "https://quaff-stage.herokuapp.com/bootstrap-custom.css.scss";
   cssLink.rel = "stylesheet";
   cssLink.type = "text/css";
   var ifrm = document.getElementById('draft-frame');
   ifrm.document.head.appendChild(cssLink);

};