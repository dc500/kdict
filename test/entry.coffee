vows     = require "vows"
assert   = require "assert"
mongoose = require "mongoose"
entry    = require "../models/entry"

db_uri = "mongodb://localhost/kdict_test"
db = mongoose.connect(db_uri)
entry.defineModel mongoose, ->
  

Entry = mongoose.model("Entry")

entryBatch = vows.describe("Entry").addBatch(
  "An entry":
    "setting korean":
      topic: ->
        new Entry()
      
      "has korean length same as hangul": (topic) ->
        topic.korean.hangul = '한국어'
        topic.save
        Entry.findById topic.id, (err, result) ->
          assert.equal topic.korean.length, 3
)

entryBatch.export module
