step = require("step")

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
  p = path.join(__dirname, directory)
  fs.readdir p, this
, readFiles = (err, results) ->
  throw err  if err
  files = []
  i = 0

  while i < results.length
    filename = results[i]
    continue  unless filename.match(/.tar$/)
    p = path.join(__dirname, "data", filename)
    stats = fs.statSync(p)
    files.push
      name: filename
      size: getTextFilesize(stats.size)
      date: stats.mtime
    i++
  files
)

exports.download = (req, res) ->
  getFiles "data", (err, files) ->
    console.log "Files baby"
    console.log files
    res.render "download",
      title: "Download"
      files: files

