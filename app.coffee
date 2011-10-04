express        = require("express")
express        = require("express")
connect        = require("connect")
jade           = require("jade")
app            = module.exports = express.createServer()
mongoose       = require("mongoose")
mongoStore     = require("connect-mongodb")
connectTimeout = require("connect-timeout")
sys            = require("sys")
path           = require("path")
fs             = require("fs")
less           = require("less")

entry          = require("./models/entry")
update         = require("./models/update")
tag            = require("./models/tag")
user           = require("./models/user")

#User   = null
#Update = null
#Entry  = null
#Tag    = null

hash = (msg, key) ->
  crypto.createHmac("sha256", key).update(msg).digest "hex"


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


Settings =
  development: {}
  test: {}
  production: {}


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
  app.set "db-uri", "mongodb://localhost/kdict_test"
  app.use express.errorHandler(
    dumpExceptions: true
    showStack: true
  )



entry.defineModel mongoose, ->
  console.log("Defined entry")

  update.defineModel mongoose, ->
    console.log("Defined update")

    tag.defineModel mongoose, ->
      console.log("Defined tag")

      user.defineModel mongoose, ->
        console.log("Defined user")

        db = mongoose.connect(app.set("db-uri"))

###
models.defineModels mongoose, ->
  console.log("Defining models")
  app.Entry  = Entry  = mongoose.model("Entry")
  app.Update = Update = mongoose.model("Update")
  app.User   = User   = mongoose.model("User")
###
  

app.error (err, req, res, next) ->
  if err instanceof NotFound
    res.render "404", status: 404
  else
    next err


# This seems kind of tightly coupled
user = require('./controllers/users')
app.get  '/login/?',            user.showLogin
app.post '/login/?',            user.login
app.get  '/logout/?',           user.logout
app.get  '/signup/?',           user.signup
app.post '/signup/?',           user.create
app.get  '/users/top/?',        user.top
app.get  '/users/:username',    user.show
app.get  '/login/reset',        user.showResetEmail
app.post '/login/reset',        user.sendResetEmail
app.get  '/login/reset/:token', user.showResetForm
app.post '/login/reset/:token', user.resetPassword

static = require('./controllers/static')
app.get '/404/?',                   static.notFound
app.get '/data/:file(*)',           static.data
app.get '/about/?',                 static.about
app.get '/contribute/?',            static.contribute
app.get '/contribute/tagged?',      static.tagged

app.get '/developers/contribute/?', static.developers
app.get '/developers/download/?',   static.download

entries = require('./controllers/entries')
app.get  '/entries/:id.:format?', entries.showById

# PROBLEM: What if we want to find all entries for 'new'
app.get  '/entries/new/?',             requireLogin, entries.new
app.post '/entries/?',                 requireLogin, entries.create
app.post '/entries/create_raw/?',      entries.create_raw
app.get  '/entries/:id.:format?/edit', entries.edit
app.put  '/entries/:id.:format?/edit', entries.update
#app.get  '/entries/:id.:format?/edit', requireLogin, entries.edit
#app.put  '/entries/:id.:format?/edit', requireLogin, entries.update
app.del  '/entries/:id.:format?',      requireLogin, entries.delete

app.get  '/entries/batch',             requireLogin, entries.batchEdit

#app.put '/entries/:id.:format?',      updates.update, requireLogin 
#app.del  '/entries/:id.:format?',     updates.delete, requireLogin

updates = require('./controllers/updates')
app.get '/updates',                   updates.list
app.get '/updates/:id',               updates.show

# This should be After all other routes
app.get  '/:word.:format?',       entries.show # Temporarily disabled



# Root
app.get "/", (req, res, next) ->
  unless isEmpty(req.query)
    entries.search req, res, next
  else
    static.index req, res, next

app.use (err, req, res, next) ->
  if "ENOENT" == err.code
    throw new NotFound
  else
    next err



app.get "*", (req, res) ->
  res.render "404", status: 404

unless module.parent
  app.listen 3000
  console.log "Express server listening on port %d, environment: %s", app.address().port, app.settings.env
  console.log "Using connect %s, Express %s, Jade %s", connect.version, express.version, jade.version

