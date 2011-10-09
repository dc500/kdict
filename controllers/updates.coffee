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
    console.log "Dumping contents of update"
    console.log update
    #res.render "updates/show", locals:
    res.render "entries/show", locals:
      entry: update.content
      title: "Update: #{update.content.korean.hangul} (#{update.id})"

