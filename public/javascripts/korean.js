(function(exports){
  
  // Taken from http://www.fileformat.info/info/unicode/block/index.htm
  var ranges = [
    // Start of range, end of range
    [ 0x0000, 0x024F, 'english'],

    [ 0x1100, 0x11FF, 'hangul' ], // Hangul Jamo	
    [ 0x3130, 0x318F, 'hangul' ], // Hangul Compatibility Jamo	
    [ 0xA960, 0xA97F, 'hangul' ], // Hangul Jamo Extended-A	
    [ 0xAC00, 0xD7AF, 'hangul' ], // Hangul Syllables	
    [ 0xD7B0, 0xD7FF, 'hangul' ], // Hangul Jamo Extended-B	

    [ 0x4E00,  0x9FFF, 'hanja' ], // CJK Unified Ideographs
    [ 0xF900, 0x2FA1F, 'hanja' ] // Massive mess of CJK and other stuff
  ];

  exports.is_type = function(text, acceptable) {
    if (!text) return null;

    var success = true
    var codes = "";
    for (var i = 0; i < text.length && success == true; i++) {
      // Want to skip spaces and numbers
      var letter = text[i];
      
      if (text[i] == " ") {
        if (!acceptable['space']) {
          success = false;
        }
      } else if (letter.match(/\d/)) {
        if (!acceptable['number']) {
          success = false;
        }
      } else {
        var code = text.charCodeAt(i);
        codes += code + ", ";
        for (var j = 0; j < ranges.length; j++) {
          if (code >= ranges[j][0] && code <= ranges[j][1]) {
            type = ranges[j][2];
            if (!acceptable[type]) {
              success = false;
            }
          }
        }
      }
    }
    return success;
  };

  // Work out whether the string has English, Korean or Kanji
  exports.detect_characters = function(text) {
    if (!text) return null;

    // Want to work out if it's a mix or not
    var result;
    var codes = "";

    // TODO numbers
    for (var i = 0; i < text.length; i++) {
      // Want to skip spaces and numbers
      if (text[i] == " ") {
        continue;
      }

      var code = text.charCodeAt(i);
      codes += code + ", ";
      for (var j = 0; j < ranges.length; j++) {
        if (code >= ranges[j][0] && code <= ranges[j][1]) {
          if (!result) {
            result = ranges[j][2];
            continue;
          }
          if (result && result != ranges[j][2]) {
            return 'mixed';
          }
        }
      }
    }

    if (!result) {
      result = 'unknown ' + codes;
    }
    
    return result;
  };

})(typeof exports === 'undefined'? this['korean']={}: exports);
