mongoose = require('mongoose')
Entry    = mongoose.model('Entry')
Tag      = mongoose.model('Tag')
korean   = require("../public/javascripts/korean.js")

NotFound = (msg) ->
  @name = "NotFound"
  Error.call this, msg
  Error.captureStackTrace this, arguments.callee

exports.show = (req, res, next) ->
  console.log "Getting for " + req.params.word
    #keyval = generalString(req.params.word)
    #query[keyval[0]] = keyval[1]
  Entry.findOne( { 'korean.hangul' : req.params.word } ).populate('updates', ['created_at']).populate('tags').run (err, entry) ->
    return next(new NotFound("Entry not found")) unless entry
    console.log entry
    res.render 'entries/show', locals:
      entry: entry
      title: entry.korean.hangul

# Is this needed?
exports.showById = (req, res, next) ->
  Entry.findById( req.params.id ).populate('updates').run (err, entry) ->
    return next(new NotFound("Entry not found")) unless entry
    console.log entry
    res.render 'entries/show', locals:
      entry: entry
      title: entry.korean.hangul

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
    max_range = (@skip + @per_page)
    if max_range > @count
      max_range = @count
    @range_str = (@skip + 1) + "-" + max_range

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
      when "tag"
        Tag.findOne( { short : val } ).run (err, tag) ->
          if !query['tags']
            query['tags'] = []
          query["tags"].push(tag._id)
      when "pos"
        query["pos"] = val
      else
        console.log "Unknown key, not going to be processing this"

  paginator = new Paginator req.query
  order = "korean.length"
  Entry.count(query).limit(paginator.limit).skip(paginator.skip).sort(order, 'ascending').run (err, count) ->
    if err
      console.log err
      next err
    else
      paginator.setCount count
      console.log paginator
      Entry.find(query).populate('tags').limit(paginator.limit).skip(paginator.skip).sort(order, 'ascending').run (err, entries) ->
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


exports.listTags = (callback) ->
  Entry.distinct "tags", (err, results) ->
    tags = {}
    for i of results
      elem = results[i]
      if elem instanceof Array
        for j of elem
          elem2 = elem[j]
          tags[elem2] = 1
      else
        tags[elem] = 1
    keys = []
    for i of tags
      keys.push i
    callback null, keys


generalString = (query) ->
  val = new RegExp(query, 'i')
  switch korean.detect_characters(query)
    when 'hangul'  then key = 'korean.hangul'
    when 'english' then key = 'meanings.definitions.english'
    when 'hanja'   then key = 'meanings.hanja'
  return [key, val]



#exports.SearchProvider = SearchProvider


exports.edit = (req, res, next) ->
  console.log "Trying to edit something. Delicious"
  Entry.findById req.params.id, (err, entry) ->
    return next(new NotFound("Entry not found"))  unless entry
    console.log "Dumping contents of D baby"
    console.log entry
    res.render "entries/edit", locals: entry: entry

exports.update = (req, res, next) ->
  console.log "Trying to update document"
  console.log req.params
  Entry.findById req.params.id, (err, entry) ->
    if err
      console.log "Save error"
      console.log err
    return next(new NotFound("Entry not found"))  unless entry
    console.log "------------------------"
    console.log "Trying to update document"
    console.log entry
    console.log "------------------------"
    console.log "Req body:"
    console.log req.body
    console.log "------------------------"
    console.log "Req params:"
    console.log req.params
    change = {}
    unless entry.korean.word == req.body.entry.korean
      change.korean = {}
      change.korean.word = req.body.entry.korean
      change.korean.length = req.body.entry.korean.length
    change.hanja = req.body.entry.hanja  unless entry.hanja == req.body.entry.hanja
    unless entry.definitions.english == [ req.body.entry.english ]
      change.definitions = {}
      change.definitions.english = req.body.entry.english
    entry.hanja = req.body.entry.hanja
    console.log "------------------------"
    console.log "Changes:"
    console.log change
    console.log "------------------------"
    console.log "Updated entry:"
    console.log entry
    entry.save (err) ->
      if err
        console.log "Save error"
        console.log err
      else
        update = new Update()
        update.change = change
        update.user_id = req.session.user._id
        update.word_id = entry._id
        update.save (err) ->
          if err
            console.log "Save error"
            console.log err
      switch req.params.format
        when "json"
          res.send entry.toObject()
        else
          req.flash "info", "Entry updated"
          res.redirect "/entries/" + req.params.id

exports.delete = (req, res, next) ->
  Entry.findById req.params.id, (err, d) ->
    return next(new NotFound("entry not found"))  unless d
    d.remove ->
      switch req.params.format
        when "json"
          res.send "true"
        else
          req.flash "info", "entry deleted"
          res.redirect "/"



exports.batchEdit = (req, res, next) ->
  console.log "Batch edit, baby"
