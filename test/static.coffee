vows   = require "vows"
assert = require "assert"
http   = require "http"
client = http.createClient(3000, 'http://localhost/')
zombie = require "zombie"

# Copied straight from the Vows tutorial
assertStatus = (code) ->
  (res) ->
    console.log "Assert status response"
    console.log res
    assert.equal res.statusCode, code

# Copied straight from the Vows tutorial
respondsWith = (status) ->
  context =
    topic: ->
      console.log "Context"
      console.log @context
      req = @context.name.split(RegExp(" +"))
      method = req[0].toLowerCase()
      path   = req[1]
      req = client.request method, path
      req.end
      req.on 'response', @callback

  
  context["should respond with a " + status + " " + http.STATUS_CODES[status]] = assertStatus(status)
  context


staticBatch = vows.describe("Static routes").addBatch(
  "GET /": respondsWith(200)
)

staticBatch.export module
