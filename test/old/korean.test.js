// Run $ expresso
var korean = require('../public/javascripts/korean.js'),
    assert = require('assert');

console.log("What");

exports.test = function() {
    assert.eql(
            korean.detect_characters('foo'),
            'english',
            'Basic testing'
            );
    assert.eql(
            korean.detect_characters('한'),
            'english',
            'Basic testing'
            );
};

console.log("What");
