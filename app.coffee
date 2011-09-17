express        = require("express")
SearchProvider = require("./search").SearchProvider
express        = require("express")
connect        = require("connect")
jade           = require("jade")
app            = module.exports = express.createServer()
mongoose       = require("mongoose")
mongoStore     = require("connect-mongodb")
mailer         = require("mailer")
connectTimeout = require("connect-timeout")
sys            = require("sys")
path           = require("path")
models         = require("./models")
fs             = require("fs")
less           = require("less")


User   = null
Update = null
Entry  = null

hash = (msg, key) ->
  crypto.createHmac("sha256", key).update(msg).digest "hex"


# Can be either username or email
authenticate = (namemail, pass, next) ->
  query = username: namemail
  if namemail =~ /@/
    query = email: namemail
    console.log 'Logging in via email'
  User.findOne query, (err, user) ->
    return next(new Error("cannot find user"))  if err or not user
    return next(null, user)  if user.authenticate
    next new Error("invalid password")

requireLogin = (req, res, next) ->
  if req.session.user
    next()
  else
    req.flash "error", "Login required"
    res.redirect "/login"

NotFound = (msg) ->
  @name = "NotFound"
  Error.call this, msg
  Error.captureStackTrace this, arguments.callee

isEmpty = (obj) ->
  for prop of obj
    return false  if obj.hasOwnProperty(prop)
  true

getFileDetails = (filename, callback) ->
  fs.stat filename, (err, stat) ->
    if err
      return callback(null, 0)  if err.errno == process.ENOENT
      return callback(err)
    callback null, [ stat.size, stat.mtime, stat.ctime ]

getTextFilesize = (bits) ->
  mb = (bits / (1024 * 1024)).toFixed(2)
  kb = (bits / (1024)).toFixed(2)
  filesize = ""
  unless Math.floor(mb) == 0
    filesize = mb + " MB"
  else
    filesize = kb + " kB"
  filesize

Settings =
  development: {}
  test: {}
  production: {}

emails =
  send: (template, mailOptions, templateOptions) ->
    mailOptions.to = mailOptions.to
    jade.renderFile path.join(__dirname, "views", "mailer", template), templateOptions, (err, text) ->
      mailOptions.body = text
      keys = Object.keys(app.set("mailOptions"))
      i = 0
      len = keys.length

      while i < len
        k = keys[i]
        mailOptions[k] = app.set("mailOptions")[k]  unless mailOptions.hasOwnProperty(k)
        i++
      console.log "[SENDING MAIL]", sys.inspect(mailOptions)
      #if app.settings.env == "production"  # SCREW IT
      mailer.send mailOptions, (err, result) ->
        console.log err  if err

  sendConfirmation: (user) ->
    @send "confirm.jade",
      to: user.email
      subject: "KDict - Please Confirm"
    , locals: user: user

  sendReset: (email, link) ->
    @send "reset.jade",
      to: email
      subject: "KDict - Confirm Password Reset"
    , locals: email: email, link: link


app = module.exports = express.createServer()
app.configure ->
  app.set "views", __dirname + "/views"
  app.set "view engine", "jade"
  app.use express.favicon()
  app.use express.bodyParser()
  app.use express.cookieParser()
  app.use connectTimeout(time: 10000)
  app.use express.session(
    store: mongoStore(app.set("db-uri"))
    secret: "kingofnopants"
  )
  app.use express.logger(format: "\u001b[1m:method\u001b[0m \u001b[33m:url\u001b[0m :response-time ms")
  app.use express.methodOverride()
  app.use express.compiler(
    src: __dirname + "/public/stylesheets"
    enable: [ "less" ]
  )
  app.use express.static(__dirname + "/public")
  app.set "mailOptions",
    host: "localhost"
    port: "25"
    from: "signup@kdict.com"


app.dynamicHelpers
  currentUser: (req, res) ->
    req.session.user

  messages: require("express-messages")


# Config

app.configure "development", ->
  app.set "db-uri", "mongodb://localhost/kdict"
  app.use express.logger()
  app.use express.errorHandler(
    dumpExceptions: true
    showStack: true
  )

app.configure "production", ->
  app.set "db-uri", "mongodb://localhost/kdict"
  app.use express.logger()
  app.use express.errorHandler()

app.configure "test", ->
  app.use express.errorHandler(
    dumpExceptions: true
    showStack: true
  )
  db = mongoose.connect("mongodb://localhost/nodepad-test")



searchProvider = new SearchProvider("localhost", 27017)
models.defineModels mongoose, ->
  console.log("Defining models")
  app.Entry  = Entry  = mongoose.model("Entry")
  app.Update = Update = mongoose.model("Update")
  app.User   = User   = mongoose.model("User")
  db = mongoose.connect(app.set("db-uri"))
  

app.error (err, req, res, next) ->
  if err instanceof NotFound
    res.render "404", status: 404
  else
    next err


# This seems kind of tightly coupled
user = require('./controllers/users')
app.get  '/signup/?',           user.signup
app.get  '/logout/?',           user.logout
app.get  '/login/?',            user.showLogin
app.post '/login/?',            user.login
app.post '/users.:format?',     user.create
app.get  '/users/top/?',        user.top
app.get  '/users/:username',    user.show
app.get  '/login/reset',        user.showResetEmail
app.post '/login/reset',        user.sendResetEmail
app.get  '/login/reset/:token', user.showResetForm
app.post '/login/reset/:token', user.resetPassword

static = require('./controllers/static')
app.get "/404/?",                   static.notFound
app.get "/data/:file(*)",           static.data
app.get "/about/?",                 static.about
app.get "/contribute/?",            static.contribute
app.get "/contribute/flagged?",     static.flagged
app.get "/contribute/developers/?", static.developers
app.get "/download/?",              static.download

entries = require('./controllers/entries')
app.get  "/entries/new/?", requireLogin, entries.new
app.post "/entries/?",     requireLogin, entries.create

updates = require('./controllers/updates')
app.get "/updates",                   updates.list
app.get "/updates/:id",               updates.show
app.get "/entries/:id.:format?/edit", updates.edit, requireLogin
app.put "/entries/:id.:format?",      updates.update, requireLogin 
app.del "/entries/:id.:format?",      updates.delete, requireLogin


app.use (err, req, res, next) ->
  if "ENOENT" == err.code
    throw new NotFound
  else
    next err


# Basic routing
app.get "/", (req, res, next) ->
  unless isEmpty(req.query)
    searchProvider.search req.query, (error, results) ->
      res.render "search",
        locals:
          results: results
          q: req.param("q")

        title: "'" + req.param("q") + "'"
  else
    res.render "index",
      title: "Korean dictionary"
      locals: q: ""



app.get "*", (req, res) ->
  res.render "404", status: 404

unless module.parent
  app.listen 3000
  console.log "Express server listening on port %d, environment: %s", app.address().port, app.settings.env
  console.log "Using connect %s, Express %s, Jade %s", connect.version, express.version, jade.version

