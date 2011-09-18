function updateDetectedLang() {
  var val = $("#search").val();
  if (val == "") {
    $("#detect").html( "" );
    $("ul#lang-select li").removeClass('selected');
    $("ul#lang-select li.selected").removeClass('selected');
    $("li#auto").addClass('selected');
    return;
  }

  var type = korean.detect_characters(val);
  // Set all to undone
  $("ul#lang-select li.selected").removeClass('selected');
  $("li#" + type).addClass('selected');
}

$(document).ready(function(){

  $("ul#lang-select a").click(function() {
    $("ul#lang-select li").removeClass('selected');
    this.parent().addClass('selected');
  });

  $("#search").keyup( updateDetectedLang );

  $("#search").focus();
  updateDetectedLang();


  $("a.show-change-raw").click(function(){
    var pre = $(this).next("pre");
    if (pre.is(":hidden")) {
      pre.slideDown();
    } else {
      pre.slideUp();
    }
    return false;
  });

  // TODO: Highlight search results



  $("body").bind("click", function (e) {
    $('.dropdown-toggle, .menu').parent("li").removeClass("open");
  });
  $(".dropdown-toggle, .menu").click(function (e) {
    var $li = $(this).parent("li").toggleClass('open');
    return false;
  });

});
