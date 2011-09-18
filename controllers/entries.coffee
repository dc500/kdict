mongoose = require('mongoose')
Entry    = mongoose.model('Entry')
korean   = require("../public/javascripts/korean.js")

# Is this needed?
exports.show = (req, res, next) ->
  query = {}
  if req.params.id
    query = { '_id' : req.params.id }
  else
    # detect language
    keyval = generalString(req.params.word)
    query[keyval[0]] = keyval[1]

  Entry.find(query).populate('updates').run (err, entries) ->
    return next(new NotFound("Entry not found")) unless entries
    console.log entries
    console.log entries.length
    if req.params.id
      title = entries[0].korean.hangul
    else
      title = req.params.word
    res.render "entries/showMultiple", locals:
      entries: entries
      title:   title

exports.new = (req, res) ->
  console.log "Displaying new form"
  res.render "entries/new", locals:
    title: "New Entry"
    entry: new Entry()

exports.create = (req, res, next) ->
  console.log "Trying to create new entry"
  console.log req.body
  entry = new Entry(
    korean:
      hangul: req.body.entry.korean
    hanja: req.body.entry.hanja
    definitions:
      english_all: req.body.entry.english
  )
  entry.user_id = req.session.user._id
  console.log "Saving..."
  console.log entry
  entry.save (err) ->
    if err
      console.log "Save error"
      console.log err
      next err
    switch req.params.format
      when "json"
        data = entry.toObject()
        data.id = data._id
        res.send data
      else
        req.flash "info", "Entry created"
        console.log "Entry created"
        res.redirect "/entries/" + entry._id



###
exports.paginatedQuery = (object, name, query, populate, order, page, per_page, callback) ->
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
###

class Paginator
  constructor: (query) ->
    @range = 5
    page = parseInt(query['pg'])
    if isNaN(page)
        page <= 1
      page = 1
    @page = page

    per_page = parseInt(query['pp'])
    if isNaN(per_page)
      per_page = 20
    else if per_page > 50
      per_page = 50
    else if per_page < 10
      per_page = 10
    @per_page = per_page

    @limit = @per_page
    @skip  = (@page - 1) * @per_page
    if (@page - @range) < 1
      @min_page = 1
    else
      @min_page = @page - @range

  setCount: (count) ->
    @count = count
    @total_pages = Math.ceil(@count / @per_page)
    if (@page + @range) > @total_pages
      @max_page = @total_pages
    else
      @max_page = @page + @range

  #limit: ->
  #  @per_page
  #skip: ->
  #  (@page - 1) * @per_page
  #range_str: ->
  #  (@skip + 1) + "-" + (@skip + @per_page)

exports.search = (req, res, next) ->
  query = {}
  for key of req.query
    val = req.query[key]
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
      else
        console.log "Unknown key, not going to be processing this"

  paginator = new Paginator req.query
  order = "korean.length"
  Entry.count(query).limit(paginator.limit).skip(paginator.skip).sort(order, 1).run (err, count) ->
    if err
      console.log err
      next err
    else
      paginator.setCount count
      console.log paginator
      Entry.find(query).limit(paginator.limit).skip(paginator.skip).sort(order, 1).run (err, entries) ->
        if err
          console.log err
          next err
        else
          console.log paginator
          console.log entries
          res.render "entries/search",
            locals:
              entries:   entries
              paginator: paginator
              q: req.param("q")
              title: "'" + req.param("q") + "'"


exports.listFlags = (callback) ->
  Entry.distinct "flags", (err, results) ->
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


generalString = (query) ->
  val = new RegExp(query, 'i')
  switch korean.detect_characters(query)
    when 'hangul'  then key = 'korean.word'
    when 'english' then key = 'definitions.english'
    when 'hanja'   then key = 'hanja'
  return [key, val]



#exports.SearchProvider = SearchProvider


