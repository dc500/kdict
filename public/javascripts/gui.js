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

function renderSearchOptions(options) {
    var output = [];
    var raw = [];
    for (i in options) {
        var option = options[i];
        if (option.type == 'tag') {
            output.push("<span class='label " + option.subtype + "'>" + option.content + "</span>");
            //output.push("<input name='tag' value='" + option.content + "' type='hidden'/>");
        } else {
            output.push("<span>" + option.content + "</span>");
            raw.push( option.content );
        }
    }
    //output.push("<input name='q' value='" + raw.join(' ') + "' type='hidden'/>");

    $('#search_parts').html(output.join(' '));
};

$(document).ready(function(){

  $("ul#lang-select a").click(function() {
    $("ul#lang-select li").removeClass('selected');
    this.parent().addClass('selected');
  });

  //
  //$("#search").keyup(parseSearch);

  // Javascript is loaded, so we can change the name tag to something else
  // And rely on Javascript to parse the content
  /*
  $("#search").attr('name', 'raw_q');
  $("#searchform").submit(function() {
      if ($(this).children('#search').val().match(/^\s*$/) {
          return false;
      }
      $(this).children('#search').remove();
  });
  */

  $("#search").focus();
  //parseSearch();
  //updateDetectedLang();

  $('.editable').editableSet({
    action: '/customer/1',
    dataType: 'json',
    afterSave: function() {
      alert( 'Saved Successfully!' );
    }
  });

  $('#topbar').dropdown();

  $("a[rel=twipsy]").twipsy({
    live: true,
    placement: 'right'
  });

  $("a[rel=popover]").popover({
    live: true,
    placement: 'below'
  });

  // How do I tie these together?
  $("a.add_sense").click(function(){
    // Hacky
    var count = parseInt($("#count").val());
    $("tbody#senses_tbody").append('<tr><td><input name="entry[senses][' + count + '][hanja_all]" value="" class="span2"/></td><td><input name="entry[senses][' + count + '][definitions][english_all]" value="" class="span6"/></td><td><select name="entry[senses][' + count + '][pos]" class="span2"><option value="">- Unknown -</option><option value="noun">noun</option><option value="verb">verb</option></select></td><td><a href="#" class="btn danger small delete_sense">&ndash;</a></td></tr>');
    //$("tbody#senses_tbody").append('<tr><td><input name="entry[hanjas][]" value="" class="span2"/></td><td><input name="entry[englishes][]" value="" class="span7"/></td><td><select name="entry[poses][]" class="span2"><option value="">- Unknown -</option><option value="noun">noun</option><option value="verb">verb</option></select></td><td><a href="#" class="btn danger small delete_sense">X</a></td></tr>');

    $("#count").val(count+1);
    return false;
  });

  $("a.delete_sense").click(function(){
    $(this).parent().parent().remove();
    //$(this).parent().parent().children('input').attr('disabled', 'disabled');
    return false;
  });


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
