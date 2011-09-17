mongoose = require("mongoose")
Entry    = mongoose.model("Entry")

exports.new = (req, res) ->
  console.log "Displaying new form"
  res.render "entries/new", locals:
    title: "New Entry"
    entry: new Entry()

exports.create = (req, res) ->
  console.log "Trying to create new entry"
  console.log req.body
  entry = new Entry(
    korean:
      word: req.body.entry.korean
      length: req.body.entry.korean.length
    hanja: req.body.entry.hanja
    definitions: english: [ req.body.entry.english ]
  )
  entry.user_id = req.session.user._id
  console.log "Saving..."
  console.log entry
  entry.save (err) ->
    if err
      console.log "Save error"
      console.log err
    switch req.params.format
      when "json"
        data = entry.toObject()
        data.id = data._id
        res.send data
      else
        req.flash "info", "Entry created"
        console.log "Entry created"
        res.redirect "/entries/" + entry._id

