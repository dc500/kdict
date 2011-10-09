url      = require('url') # for pagination
qs       = require('querystring')
async    = require('async')
mongoose = require('mongoose')
Entry    = mongoose.model('Entry')
Update   = mongoose.model('Update')
Tag      = mongoose.model('Tag')
Korean   = require("../public/javascripts/korean.js")
Search   = require("../public/javascripts/search.js")

NotFound = (msg) ->
  @name = "NotFound"
  Error.call this, msg
  Error.captureStackTrace this, arguments.callee

exports.show = (req, res, next) ->
  console.log "Getting for " + req.params.word
    #keyval = generalString(req.params.word)
    #query[keyval[0]] = keyval[1]
  Entry.findOne( { 'korean.hangul' : req.params.word } ).populate('tags').run (err, entry) ->
    return next(new NotFound("Entry not found")) unless entry
    Update.find( { 'entry.id' : entry.id } ).run (err, updates) ->
      console.log updates
      return next(new NotFound("Updates not found")) unless updates
      
      console.log entry
      res.render 'entries/show',
        locals:
          entry: entry
          updates: updates
          title: entry.korean.hangul

# Is this needed?
exports.showById = (req, res, next) ->
  Entry.findById( req.params.id ).populate('updates').run (err, entry) ->
    return next(new NotFound("Entry not found")) unless entry
    console.log entry
    res.render 'entries/show',
      locals:
        entry: entry
        title: entry.korean.hangul

exports.new = (req, res) ->
  console.log "Displaying new form"
  res.render "entries/new",
    locals:
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


exports.create_raw = (req, res, next) ->
  # Entry is JSON baby!
  entry_raw = JSON.parse(req.body.entry_json)
  entry = new Entry( entry_raw )
  entry.save (err) ->
    if err
      console.log "Save error"
      console.log entry_raw
      console.log entry
      console.log err
      next err
    else
      data = entry.toObject()
      data.id = data._id
      res.send data

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
  constructor: (req) ->
    query = req.query

    @raw = query
    @range = 5
    page = parseInt(query['pg'])
    if isNaN(page) || page < 1
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

    parts = url.parse req.url, true
    delete parts.search
    @raw_parts = parts


    if (@page - 1 >= @min_page)
      parts.query['pg'] = @page - 1
      @prev_page_url = url.format(parts)

    if (@page + 1 <= @max_page)
      parts.query['pg'] = @page + 1
      @next_page_url = url.format(parts)

  getPgUrl: (pg) ->
    @raw_parts.query['pg'] = pg
    return url.format(@raw_parts)

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

Object.extend = (destination, source) ->
  for property of source
    if source.hasOwnProperty(property)
      destination[property] = source[property];
  return destination;

# Q is essentially free text
parseQ = (text, next) ->
  next() if not text or text.match /^\s*$/

  words = text.split(" ")
  async.map words, parseWord, (err, results) ->
    next(results)
    
    # Merge results by key
      #merged = {}
      #for i of results
      #  # There's only going to be one key but this seems to be the only way
      #  for key,val of results[i]
      #    if !merged[key]
      #      merged[key] = []
      #    merged[key].push val
      #console.log "Merged"
      #console.log merged
      #next(merged)

# This should only be used by the GUI, really
# the Q thing should never have
parseWord = (word, next) ->
  switch word.charAt(0)
    when '!', '#'
      parseTag word, next
    when '.'
      parsePOS word, next
    else
      parseText word, next

# Parse Q, move !tag stuff to appropriate GET stuff and redirect
#exports.parseAndRedirect = (req, res, next) ->




parseTag = (word, next) ->
  short = word.substr(1, word.length - 1)
  switch word.charAt(0)
    when '!' then type = 'problem'
    when '#' then type = 'user'

  Tag.findOne { 'short' : short, 'type' : type }, (err, tag) ->
    if !tag
      next err
    else
      next( null, { 'tags' : tag._id } )

parsePOS = (word, next) ->
  without_dot = word.substr(1, word.length - 1)
  next( null, { 'senses.pos' : without_dot } )

parseText = (word, next) ->
  val = new RegExp(word, 'i')
  switch Korean.detect_characters(word)
    when 'hangul'
      next(null, { 'korean.hangul' : val })
    when 'english'
      next(null, { 'senses.definitions.english' : val })
    when 'hanja'
      next(null, { 'senses.hanja' : val })

# Parse a single GET parameter
parseParam = (pair, next) ->
  key = pair[0]
  val = pair[1]
  switch key
    when "q"
      console.log "Parsing q"
      parseQ val, (results) ->
        console.log "Keyval q outer results: "
        console.log results
        next(null, results)

    when "tags"
      tags = val.split(' ')
      console.log "Raw tags"
      console.log tags
      async.map tags, parseTag, (err, results) ->
        console.log "Parsed tags"
        console.log results
        next(null, results)
    
    # Looking for entries with multiple POS doesn't really make sense
    # although I guess you could look for words that have senses where they're
    # both a noun and a verb. That might be handy
    when "pos"
      pos = val.split(' ')
      async.map pos, parsePOS, (err, results) ->
        next(null, results)

    else
      console.log "Unknown key, not going to be processing this"
      next

exports.search = (req, res, next) ->
  query = {}
  pairs = []
  for key of req.query
    pairs.push( [ key, req.query[key] ] )

  async.map pairs, parseParam, (err, results) ->
    # Results will be an array of arrays.
    # q, tags, pos
    #    each thing within that

    query = {}

    for i, arr of results
      #console.log "Key:"
      #console.log key
      #console.log "Val:"
      #console.log val
      for j, pair of arr
        for key, val of pair # Not really iterating, just only way to get key/val
          # Query already exists
          if (!query[key])
            query[key] = val
          else
            # If there's only one existing thing, we need to make it into an array first
            if (query[key].length = 1)
              old = query[key]
              query[key] = { '$all' : [ old ] }
            query[key]['$all'].push( val )

    console.log "Query:"
    console.log query
  
    paginator = new Paginator req
    order = "korean.hangul_length"
    Entry.count(query).limit(paginator.limit).skip(paginator.skip).sort(order, 'ascending').run (err, count) ->
      if err
        console.log err
        next err
      else
        paginator.setCount count
        Entry.find(query).populate('tags').limit(paginator.limit).skip(paginator.skip).sort(order, 'ascending').run (err, entries) ->
          if err
            console.log err
            next err
          else
            console.log paginator
            console.log entries.size
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

#exports.SearchProvider = SearchProvider


exports.edit = (req, res, next) ->
  console.log "Trying to edit something. Delicious"
  Entry.findById req.params.id, (err, entry) ->
    return next(new NotFound("Entry not found"))  unless entry
    console.log "Dumping contents of D baby"
    console.log entry
    all_pos = ['noun', 'verb']  # TODO Get all parts of speech
    res.render "entries/edit",
      locals:
        entry: entry
        all_pos: all_pos

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

    #change = {}
    #unless entry.korean.hangul == req.body.entry.korean.hangul
    #  change.korean = {}
    #  change.korean.korean.hangul = req.body.entry.korean.hangul

    #console.log "Changes:"
    #console.log change
    #console.log "------------------------"

    #console.log req.body.entry.senses.length
    #console.log entry.senses.length
    #console.log "------------------------"

    #for sense, i in req.body.entry.senses
    #  console.log "Sense"
    #  console.log sense
    #  console.log i
    #  unless entry.senses[i].hanja == sense.hanja
    #    if not change.senses
    #      change.senses = []
    #    change.senses[i] = {}
    #    change.senses[i].hanja = sense.hanja
    #  
    #  unless entry.senses[i].english_all == sense.english_all
    #    english_defs = sense.all_english.split(';')
    #    for def, j in english_defs
    #      change.senses[i].english[j] = def

    entry.korean.hangul = req.body.entry.korean.hangul

    reduced_senses = []
    for val, i in req.body.entry.senses
      if val
        reduced_senses.push val
    entry.senses = reduced_senses

    console.log "Updated entry:"
    console.log entry
    console.log "Sample definitions"
    console.log entry.senses[0].definitions
    entry.save (err) ->
      console.log "Tried saving"
      if err
        console.log "Save error"
        console.log err
        req.flash "error", err
        all_pos = ['noun', 'verb']  # TODO Get all parts of speech
        console.log entry
        res.render "entries/edit",
          locals:
            entry: entry
            all_pos: all_pos
      else
        console.log "Successful save"
        #update = new Update()
        #update.change = change
        #update.user_id = req.session.user._id
        #update.word_id = entry._id
        #update.save (err) ->
        #  if err
        #    console.log "Save error"
        #    console.log err
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

