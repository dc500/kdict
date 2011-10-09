zombie = require "zombie"
assert = require "assert"
app    = require "../app"
vows_bdd = require "vows-bdd"
mongoose = require "mongoose"
entry    = require "../models/entry"
e        = require "./entry-helper"
http = require("http")

process.env.NODE_ENV = 'test'

port = 3001
app.listen port
# TODO Set something so the DB is set up to use kdict_test
#db_uri = "mongodb://localhost/kdict_test"
#db = mongoose.connect(db_uri)
#entry.defineModel mongoose, -> 
Entry  = mongoose.model("Entry")


vows.describe("Raw entry").addBatch(
  "A raw":
    "submitted via create_raw":

    "with english_all attribute":
      topic: ->
        entry = new Entry
          korean:
            hangul: "사랑"
          senses: [
            definitions: {
              english: [ "love", "cheesecake" ]
            }
          ]
        local   = http.createClient(port, "http://localhost/")
        request = local.request("POST", "/entries/post_raw",
          host: "http://localhost/"
          "content-type": "application/json"
        )
        request.write JSON.stringify(entry), encoding = "utf8"
        request.end()
        request.on_ "response", (response) ->
          Entry.find( { 'korean.hangul' : '사랑' } ).run @callback
          #console.log "STATUS: " + response.statusCode
          #console.log "HEADERS: " + JSON.stringify(response.headers)
          #response.setEncoding "utf8"
          #response.on_ "data", (chunk) ->
          #  console.log "BODY: " + chunk

      "should have created an entry in the DB": (err, entry) ->
        assert.equal entry.korean.hangul, '사랑'

        pair = entry.senses[0].definitions.english
        test = [ "love", "cheesecake" ]
        assert.equal pair[0], test[0]
        assert.equal pair[1], test[1]

).export module
