vows   = require "vows"
assert = require "assert"
http   = require "http"
zombie = require "zombie"

port = 3001
app = require "../app"
app.listen port


assertStatus = (code) ->
  (e, b, s) ->
    assert.equal s, code

respondsWith = (status) ->
  context =
    topic: ->
      req = @context.name.split(RegExp(" +"))
      second   = req[0]
      zombie.visit "http://localhost:#{port}" + second, @callback
  
  context["should respond with a " + status + " " + http.STATUS_CODES[status]] = assertStatus(status)
  context


staticBatch = vows.describe("Static routes").addBatch(
  "Getting static routes":
    "/":                      respondsWith(200)
    "/contribute":            respondsWith(200)
    "/contribute/tagged":     respondsWith(200)
    "/developers/contribute": respondsWith(200)
    "/about":                 respondsWith(200)
    #"/404":                   respondsWith(404)

  #"GET /": respondsWith(200)
)

staticBatch.export module

