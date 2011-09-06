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
});





/*
$("#search").live("blur", function(){
    var default_value = $(this).attr("rel");
    $(this).addClass("active");
    if ($(this).val() == ""){
        $(this).val(default_value);
    }
}).live("focus", function(){
    var default_value = $(this).attr("rel");
    $(this).addClass("active");  
    if ($(this).val() == default_value){
        $(this).val("");
    }
});

*/
