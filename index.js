require.paths.unshift('/Users/ben/node_modules');
var http = require('http');
http.createServer(function (req, res) {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('Hello World\n');
}).listen(1337, "127.0.0.1");
console.log('Server running at http://127.0.0.1:1337/');


var sys = require('sys');
//var Mu = require('./lib/mu');
var Mustache = require('Mustache');

Mustache.templateRoot = './templates';

var ctx = {
  name: "Chris",
  value: 10000,
  taxed_value: function() {
    return this.value - (this.value * 0.4);
  },
  in_ca: true
};

Mustache.render('simple.html', ctx, {}, function (err, output) {
  if (err) {
    throw err;
  }

  var buffer = '';

  output.addListener('data', function (c) {buffer += c; })
        .addListener('end', function () { sys.puts(buffer); });
});


/*
var client = new Db('test', new Server("127.0.0.1", 27017, {})),
    test = function (err, collection) {
      collection.insert({a:2}, function(err, docs) {

        collection.count(function(err, count) {
          test.assertEquals(1, count);
        });

        // Locate all the entries using find
        collection.find().toArray(function(err, results) {
          test.assertEquals(1, results.length);
          test.assertTrue(results.a === 2);

          // Let's close the db
          client.close();
        });
      });
    };

client.open(function(err, p_client) {
  client.collection('test_insert', test);
});
*/
