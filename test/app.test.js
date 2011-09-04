// Run $ expresso

/**
* Module dependencies.
*/

var app = require('../app')
  , assert = require('assert');

module.exports = {
  'GET /': function(){
    assert.response(app,
      { url: '/' },
      { status: 200, headers: { 'Content-Type': 'text/html; charset=utf-8' }},
      function(res){
        assert.includes(res.body, 'KDict');
      });
  },

  'Search baby': function(){
    assert.response(app,
      { url: '/',
        method: 'GET',
        headers: { 'content-type': 'application/x-www-form-urlencoded; charset=UTF-8' },
        data: 'q=hello'
      },
      { status: 200, headers: { 'Content-Type': 'text/html; charset=utf-8' }},
      function(res){
        assert.includes(res.body, '안녕');
      });
  }

  /*
  'POST RAW body to /foo': function(){
    assert.response(app,
      { url: '/foo',
        method: 'POST',
        headers: { 'content-type': 'application/x-www-form-urlencoded; charset=UTF-8' },
        data: 'name=jody&commit=Start'
      },
      { status: 200, headers: { 'Content-Type': 'text/html; charset=utf-8' }},
      function(res){
        assert.includes(res.body, 'jody');
      });
  }
  */

};

