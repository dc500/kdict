$(document).ready(function(){

    var searchDefault = $("#search").val();
    $("#search").focus(function(){  
        if ($("#search").val() == searchDefault) {
            $("#search").val("");  
        }
    });

    $("#search").blur(function(){  
        if ($("#search").val() == "") {
            $("#search").val(searchDefault);  
        }
    });  

    $("#search").focus();
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
