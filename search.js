var Db         = require('mongodb').Db;
var Connection = require('mongodb').Connection;
var Server     = require('mongodb').Server;
var BSON       = require('mongodb').BSON;
var ObjectID   = require('mongodb').ObjectID;


SearchProvider = function(host, port) {
  this.db = new Db('kdict', new Server(host, port, {auto_reconnect: true}, {}));
  this.db.open(function(){});
};


SearchProvider.prototype.getCollection = function(callback) {
    this.db.collection('entries', function(error, dict_collection) {
        if (error) callback(error);
        else callback(null, dict_collection);
    });
};


SearchProvider.prototype.search = function(query, callback) {
    if (!query) {
        callback(null, null);
    }
    else {
        this.getCollection(function(error, dict_collection) {
            if (error) callback(error)
            else {
                var re = new RegExp(query, 'i');

                var obj = { 'korean.word' : re };
                var language = 'Korean';
                var order = 'korean.length';
                // Trying to work out if it's korean or not
                if (query.match(/^[a-z0-9 -.,]/)) {
                    obj = { 'definitions.english' : re };
                    language = 'English';
                    //order = 'definitions.english.length';
                }
                var limit = 20;
                var skip = 0;
                var cursor = dict_collection.find( obj ).limit(limit).skip(skip).sort(order);
                cursor.count(function(error, count){
                    if (error) callback(error)
                    else {
                        cursor.toArray(function(error, entries) {
                            if (error) callback(error)
                            else {
                                results = {
                                    'language': language,
                                    'entries':  entries,
                                    'count':    count,
                                };
                                console.log("Results!");
                                callback(null, results);
                            }
                        });
                    }
                });
            }
        });
    }
};

exports.SearchProvider = SearchProvider;

