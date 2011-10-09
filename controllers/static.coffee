step = require("step")
path = require("path")
fs   = require("fs")
mongoose = require('mongoose')
Entry    = mongoose.model('Entry')
Update   = mongoose.model('Update')
User     = mongoose.model('User')
Tag      = mongoose.model('Tag')


exports.notFound = (req, res) ->
  res.render "404", status: 404

exports.data = (req, res, next) ->
  file = req.params.file
  path = __dirname + "/data/" + file
  res.download path, ((err) ->
    return next(err) if err
    console.log "transferred %s", path
  ), (err) ->

exports.index = (req, res, next) ->
  User.find().sort('score', 1).limit(10).run (err, top_users) ->
    return next(err) if err
    Update.find( type: "new" ).populate('user').sort('created_at', 1).limit(10).run (err, new_updates) ->
      return next(err) if err
      Update.find().populate('user').sort("created_at", 1).limit(10).run (err, updates) ->
        console.log updates
        return next(err) if err
        res.render "index",
          title: "Korean dictionary"
          locals:
            q: ""
            top_users:      top_users
            new_updates:    new_updates
            recent_updates: updates

exports.about = (req, res) ->
  res.render "about", title: "About"

exports.contribute = (req, res) ->
  res.render "contribute", title: "Contribute"

exports.tagged = (req, res) ->
  Tag.find( { type : 'problem' } ).run (err, problem_tags) ->
    return next(err) if err
    res.render "contribute/tagged",
      problem_tags: problem_tags
      title: "Tagged Entries"

exports.developers = (req, res) ->
  res.render "contribute/developers", title: "Developers"


getFiles = step.fn(readDir = (directory) ->
  console.log "Reading directory"
  p = path.join(__dirname, directory)
  console.log p
  fs.readdir p, this
, readFiles = (err, results) ->
  console.log "Reading files"
  throw err if err
  console.log "Still good"
  files = []
  console.log results
  for filename in results
    console.log filename
    continue unless filename.match(/.tar$/)
    p = path.join(__dirname, "../data", filename)
    bits = filename.split(".")
    parts = bits[bits.length - 2].split("-")
    filetype = parts[parts.length - 1]
    console.log p
    stats = fs.statSync(p)
    files.push
      name: filename
      type: filetype
      size: getTextFilesize(stats.size)
      date: stats.mtime
  return files
)

getTextFilesize = (bits) ->
  mb = (bits / (1024 * 1024)).toFixed(2)
  kb = (bits / (1024)).toFixed(2)
  filesize = ""
  unless Math.floor(mb) == 0
    filesize = mb + " MB"
  else
    filesize = kb + " kB"
  filesize

exports.download = (req, res) ->
  getFiles "../data", (err, files) ->
    console.log err
    console.log "Files baby"
    console.log files
    res.render "download",
      title: "Download"
      files: files

