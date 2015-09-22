window.onload = function() {

   //Params
   var scriptPram = document.getElementById('load_widget');
   var id = scriptPram.getAttribute('data-page');

   //iFrame
   var iframe = document.createElement('iframe');
   iframe.style.display = "none";
   iframe.src = "https://quaff-stage.herokuapp.com/draft_boards/1.column-web";  //"draft/" + id;
   document.body.appendChild(iframe);
};