mongoose = require("mongoose")
Update   = mongoose.model("Update")

exports.list = (req, res, next) ->
  if (req.params['pg'])
    page = parseInt(req.params['pg'])
  if (req.params['pp'])
    per_page = parseInt(req.params['pp'])
    if (per_page > 50)
      per_page = 50
  order = "date"
  range = 10
  skip = (page - 1) * per_page
  console.log "Getting page " + page + ", limit " + per_page + " skip " + skip

  #searchProvider.paginatedQuery app.Update, 'updates', ['user'], 'date', req.params['pg'], req.params['pp'], (error, data) ->
  Update.find().populate('user').limit(20).run (error, data) ->
    if error
      res.render "404", status: 404
      #res.redirect "/entries/" + req.params.id
    else
      res.render "updates/index", locals:
        title: 'Updates'
        results:  data


    console.log "Updates"


# Is this needed?
exports.show = (req, res, next) ->
  Update.findById req.params.id, (err, update) ->
    return next(new NotFound("Entry not found"))  unless update
    console.log "Dumping contents of D baby"
    console.log update
    res.render "updates/show", locals:
      update: update
      title: 'Update: '.update.korean.word


exports.edit = (req, res, next) ->
  console.log "Trying to edit something. Delicious"
  Entry.findById req.params.id, (err, entry) ->
    return next(new NotFound("Entry not found"))  unless entry
    console.log "Dumping contents of D baby"
    console.log entry
    res.render "entries/edit", locals: entry: entry

exports.update = (req, res, next) ->
  console.log "Trying to update document"
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

