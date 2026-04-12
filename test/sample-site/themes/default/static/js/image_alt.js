$(document).ready(function(){
  $("#posts img").each(function(i){
    // Adds a caption below the image using the alt text
    if ($(this).attr("alt") && $(this).attr("alt").length) {
      $(this).after("<div class=\"image-footnote\">" + $(this).attr("alt") + "</div>");
    }
  });
});
