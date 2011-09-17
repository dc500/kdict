function updateDetectedLang() {
    var val = $("#search").val();
    if (val == "") {
        $("#detect").html( "" );
        return;
    }

    var type = korean.detect_characters(val);
    $("#detect").html( "Language: " + type );
}

$(document).ready(function(){

    //var searchDefault = $("#search").val();
    $("#search").focus(function(){  
        $("#search").addClass('active');

        /*
        if ($("#search").val() == searchDefault) {
            $("#search").val("");  
        }
        */
    });

    $("#search").blur(function(){  
        $("#search").removeClass('active');
        /*
        if ($("#search").val() == "") {
            $("#search").val(searchDefault);  
        }
        */
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
    


    $("body").bind("click", function (e) {
        $('.dropdown-toggle, .menu').parent("li").removeClass("open");
    });
    $(".dropdown-toggle, .menu").click(function (e) {
        var $li = $(this).parent("li").toggleClass('open');
        return false;
    });

});
