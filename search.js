var Db         = require('mongodb').Db;
var Connection = require('mongodb').Connection;
var Server     = require('mongodb').Server;
var BSON       = require('mongodb').BSON;
var ObjectID   = require('mongodb').ObjectID;

var korean = require('./public/javascripts/korean.js');


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


SearchProvider.prototype.search = function(query, page, per_page, callback) {
    if (!query) {
        callback(null, null);
    }
    else {
        this.getCollection(function(error, dict_collection) {
            if (error) callback(error)
            else {
                var re = new RegExp(query, 'i');

                var obj;
                var language;

                console.log("What");
                switch(korean.detect_characters(query)) {
                    case 'korean':
                        obj = { 'korean.word' : re };
                        language = 'Korean';
                        break;
                    case 'english':
                        obj = { 'definitions.english' : re };
                        language = 'English';
                        break;
                    case 'hanja':
                        obj = { 'hanja' : re };
                        language = 'Hanja';
                        break;
                    default:
                        callback(null, null);
                }
                console.log(language);

                var order = 'korean.length';
                // Trying to work out if it's korean or not
                if (query.match(/^[a-z0-9 -.,]/)) {
                    //order = 'definitions.english.length';
                }
                var limit = per_page;
                var skip = (page-1) * per_page;
                console.log("Getting page " + page + ", limit " + limit + " skip " + skip);
                var range = 10;


                var cursor = dict_collection.find( obj ).limit(limit).skip(skip).sort(order);
                cursor.count(function(error, count){
                    if (error) callback(error)
                    else {
                        cursor.toArray(function(error, entries) {
                            if (error) callback(error)
                            else {

                                var total_pages =  Math.ceil(count / per_page);
                                var min_page = (page - range) < 1 ? 1 : (page - range);
                                var max_page = (page + range) > total_pages ? total_pages : (page + range);
                                results = {
                                    'language':     language,
                                    'entries':      entries,
                                    'query':        query,
                                    'count':        count,
                                    'per_page':     per_page,
                                    'range':        (skip+1) + "-" + (skip+per_page),
                                    'current_page': page,
                                    'total_pages':  total_pages,
                                    'min_page':     min_page,
                                    'max_page':     max_page,
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

