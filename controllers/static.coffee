step = require("step")
path = require("path")
fs   = require("fs")

exports.notFound = (req, res) ->
  res.render "404", status: 404

exports.data = (req, res, next) ->
  file = req.params.file
  path = __dirname + "/data/" + file
  res.download path, ((err) ->
    return next(err)  if err
    console.log "transferred %s", path
  ), (err) ->


exports.about = (req, res) ->
  res.render "about", title: "About"

exports.contribute = (req, res) ->
  res.render "contribute", title: "Contribute"

exports.flagged = (req, res) ->
  searchProvider.getFlags (error, flags) ->
    res.render "contribute/flagged",
      flags: flags
      title: "Flagged Entries"

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
    console.log p
    stats = fs.statSync(p)
    files.push
      name: filename
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

