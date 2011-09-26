(function(exports){

    exports.parseSearch = function(text) {
        if (!text || text == '') {
            return;
        }

        var words = text.split(' ');
        var options = [];

        for (i in words) {
            var word = words[i];
            // Problem
            var option = {};
            if (word.charAt(0) == "!" || word.charAt(0) == "#") {
                option.type    = 'tag';
                switch (word.charAt(0)) {
                    case "!":
                        option.subtype = 'problem';
                        break;
                    case "#":
                        option.subtype = 'user';
                        break;
                }
                option.content = word.substr(1, word.length-1);
            } else if (word.charAt(0) == ".") {
                option.type    = 'pos';
                option.content = word.substr(1, word.length-1);
            } else {
                option.type    = 'text';
                option.content = word;
            }
            options.push(option);
        }
        return options
        //renderSearchOptions(options);
    };

})(typeof exports === 'undefined'? this['search']={}: exports);

