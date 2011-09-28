vows     = require "vows"
assert   = require "assert"
mongoose = require "mongoose"
tag      = require "../models/tag"

db_uri = "mongodb://localhost/kdict_test"
db = mongoose.connect(db_uri)
tag.defineModel mongoose, ->
  

Tag = mongoose.model("Tag")

tagBatch = vows.describe("Tag").addBatch(
  "A tag":
    "when creating new tag with a duplicate short name":
      topic: ->
        existing = new Tag(
          long:  'Some tag'
          short: '!snowflake'
          type:  'problem'
        )
        existing.save

        dup = new Tag
          long:  'whatever'
          short: '!snowflake'
          type:  'problem'
        dup.save this.callback

      "it fails": (err, tag) ->
        console.log err
        assert.notEqual err, null

    "when creating perfect tag":
      topic: ->
        mix = new Tag
          long: 'Some tag'
          short: '!snowflake'
          type: 'problem'
        mix.save this.callback
      
      "it succeeds": (err, tag) ->
        assert.equal err, null
    
    "when creating tag where type does not match short name prefix":
      topic: ->
        mix = new Tag
          long: 'Some tag'
          short: '!snowflake'
          type: 'user'
        mix.save this.callback
      
      "it fails": (err, tag) ->
        assert.notEqual err, null

    "when creating tag with short name without prefix":
      topic: ->
        mix = new Tag
          long:  'Some tag'
          short: 'snowflake'
          type:  'user'
        mix.save this.callback
      
      "it fails": (err, tag) ->
        assert.notEqual err, null
)

tagBatch.export module
