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


SearchProvider.prototype.getFlags = function(callback) {
    this.getCollection(function(error, dict_collection) {
        dict_collection.distinct( "flags", function(error, results) {
            // The results are usually a mess of nested flags
            // TODO fix this hack

            //console.log(results);
            var flags = {};
            for (var i in results) {
                var elem = results[i];
                //console.log("elem " + i + " " + elem);
                if (elem instanceof Array) {
                    for (var j in elem) {
                        var elem2 = elem[j];
                        //console.log("elem2 " + j + " " + elem2);
                        flags[elem2] = 1;
                    }
                } else {
                    flags[elem] = 1;
                }
            }

            var keys = [];
            for(var i in flags) { //if (this.hasOwnProperty(i)) {
                //console.log(i);
                keys.push(i);
            }
            callback( null, keys );
        });
    });
};


SearchProvider.prototype.search = function(params, callback) {
    if (!params) {
        callback(null, null);
    } else {
        this.getCollection(function(error, dict_collection) {
            if (error) callback(error)
            else {
                var query = {};
                // Parse each param

                var page     = 1;
                var per_page = 20;
                for (var key in params) {
                    var val = params[key];
                    console.log('key: ' + key + ', val: ' + val);
                    // treat each one individually
                    switch(key) {
                        case 'q':
                            var keyval = generalString(val);
                            query[keyval[0]] = keyval[1];
                            break;
                        case 'flag':
                            var re = new RegExp(val, 'i');
                            query['flags'] = re;
                            break;

                        case 'pos':
                            query['pos'] = val;
                            break;

                        case 'pg':
                            page = parseInt(val);
                            break;
                        case 'pp':
                            pp = parseInt(val);
                            break;
                        
                        default:
                            console.log("Unknown key, not going to be processing this");
                            break;
                    }
                }

                var order = 'korean.length';
                var limit = per_page;
                var skip = (page-1) * per_page;
                console.log("Getting page " + page + ", limit " + limit + " skip " + skip);
                var range = 10;

                var cursor = dict_collection.find( query ).limit(limit).skip(skip).sort(order);
                cursor.count(function(error, count){
                    if (error) callback(error)
                    else {
                        cursor.toArray(function(error, entries) {
                            if (error) callback(error)
                            else {

                                var total_pages = Math.ceil(count / per_page);
                                var min_page = (page - range) < 1 ? 1 : (page - range);
                                var max_page = (page + range) > total_pages ? total_pages : (page + range);
                                results = {
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
                                callback(null, results);
                            }
                        });
                    }
                });
            }
        });
    }
};

// The following methods all pre-parse various parameters
function generalString( query ) {
    var key;
    var val = new RegExp(query, 'i');

    switch(korean.detect_characters(query)) {
        case 'korean':
            key = 'korean.word';
            break;
        case 'english':
            key = 'definitions.english';
            break;
        case 'hanja':
            key = 'hanja';
            break;
        default:
    }
    return [key, val];
};

exports.SearchProvider = SearchProvider;

