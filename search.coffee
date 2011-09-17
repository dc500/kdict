Db         = require("mongodb").Db
Connection = require("mongodb").Connection
Server     = require("mongodb").Server
BSON       = require("mongodb").BSON
ObjectID   = require("mongodb").ObjectID
korean     = require("./public/javascripts/korean.js")

SearchProvider = (host, port) ->
  @db = new Db("kdict", new Server(host, port, auto_reconnect: true, {}))
  @db.open ->

SearchProvider::getCollection = (name, callback) ->
  @db.collection name, (error, collection) ->
    if error
      callback error
    else
      callback null, collection

SearchProvider::paginatedQuery = (object, name, query, populate, order, page, per_page, callback) ->
  page     = 1      unless page
  per_page = 20     unless per_page
  per_page = 50     unless page < 50
  order    = "date" unless order
  query    = {}     unless query
  populate = null   unless populate
  range = 10
  skip = (page - 1) * per_page
  console.log "Getting page " + page + ", limit " + per_page + " skip " + skip

  @getCollection name, (error, collection) ->
    cursor = object.find(query).populate('user').limit(per_page).skip(skip).sort(order)
    #for prop of populate
    #  cursor = cursor.populate(prop)
    cursor.count (error, count) ->
      if error
        callback error
      else
        #cursor.toArray (error, results) ->
        cursor.run (error, results) ->
          if error
            callback error
          else
            total_pages = Math.ceil(count / per_page)
            min_page = (if (page - range) < 1 then 1 else (page - range))
            max_page = (if (page + range) > total_pages then total_pages else (page + range))
            data =
              results:  results
              count:    count
              per_page: per_page
              pagination:
                range:    (skip + 1) + "-" + (skip + per_page)
                current_page: page
                total_pages: total_pages
                min_page: min_page
                max_page: max_page

            callback null, data


SearchProvider::getFlags = (callback) ->
  @getCollection 'entries', (error, dict_collection) ->
    dict_collection.distinct "flags", (error, results) ->
      flags = {}
      for i of results
        elem = results[i]
        if elem instanceof Array
          for j of elem
            elem2 = elem[j]
            flags[elem2] = 1
        else
          flags[elem] = 1
      keys = []
      for i of flags
        keys.push i
      callback null, keys

SearchProvider::search = (params, callback) ->
  unless params
    callback null, null
  else
    @getCollection 'entries', (error, dict_collection) ->
      if error
        callback error
      else
        query = {}
        page = 1
        per_page = 20
        for key of params
          val = params[key]
          console.log "key: " + key + ", val: " + val
          switch key
            when "q"
              keyval = generalString(val)
              query[keyval[0]] = keyval[1]
            when "flag"
              re = new RegExp(val, "i")
              query["flags"] = re
            when "pos"
              query["pos"] = val
            when "pg"
              page = parseInt(val)
            when "pp"
              pp = parseInt(val)
            else
              console.log "Unknown key, not going to be processing this"
        order = "korean.length"
        limit = per_page
        skip = (page - 1) * per_page
        console.log "Getting page " + page + ", limit " + limit + " skip " + skip
        range = 10
        cursor = dict_collection.find(query).limit(limit).skip(skip).sort(order)
        cursor.count (error, count) ->
          if error
            callback error
          else
            cursor.toArray (error, entries) ->
              if error
                callback error
              else
                total_pages = Math.ceil(count / per_page)
                min_page = (if (page - range) < 1 then 1 else (page - range))
                max_page = (if (page + range) > total_pages then total_pages else (page + range))
                results = 
                  entries: entries
                  query: query
                  count: count
                  per_page: per_page
                  range: (skip + 1) + "-" + (skip + per_page)
                  current_page: page
                  total_pages: total_pages
                  min_page: min_page
                  max_page: max_page

                callback null, results

generalString = (query) ->
  val = new RegExp(query, 'i')
  switch korean.detect_characters(query)
    when 'korean'  then key = 'korean.word'
    when 'english' then key = 'definitions.english'
    when 'hanja'   then key = 'hanja'
  return [key, val]



exports.SearchProvider = SearchProvider

