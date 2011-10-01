vows     = require "vows"
assert   = require "assert"
mongoose = require "mongoose"
tag      = require "../models/tag"
helpers  = require "./helpers"

db_uri = "mongodb://localhost/kdict_test"
db = mongoose.connect(db_uri)

tag.defineModel mongoose, ->
  
model =
  single: (short, type, long) ->
    ->
      tag = new Tag
        short: short
        type:  type
      if long
        tag.long = long
      tag.save @callback
 
Tag = mongoose.model("Tag")

# Drop tags
Tag.collection.drop()

tagBatch = vows.describe("Tag").addBatch(
  "A tag":
    "when creating tag where type does not match short name prefix":
      topic: model.single("!cheesecake", "user")
      "it fails": helpers.assertPropErr("short")

    "when creating tag with short name without prefix":
      topic: model.single("noprefix", "user")
      "it fails": helpers.assertPropErr("short")

    "when creating tag with short name with spaces":
      topic: model.single("@hello there", "user")
      "it fails": helpers.assertPropErr("short")

    "when creating perfect tag":
      topic: ->
        tag = new Tag
          short: "!magical"
          type:  "problem"
        tag.save this.callback
        #model.single("!magical", "problem")

      "it succeeds": (err, tag) ->
        assert.isNull    err
        assert.isNotNull tag
        assert.equal tag.short, "!magical"
        assert.equal tag.long,  ""
        assert.equal tag.type,  "problem"
    
)
.addBatch(
  "A tag":
    "when creating new tag with a duplicate short name":
      topic: ->
        existing = new Tag
          long:  "Some tag"
          short: "!snowflake"
          type:  "problem"
        existing.save this.callback #(e, t) ->
        #  if e
        #    console.log e
        #  dup = new Tag
        #    long:  "whatever"
        #    short: "!snowflake"
        #    type:  "problem"
        #  dup.save @callback
        ###
        (err, tag) ->
          console.log "Before"
          console.log err
          console.log tag
          if err
            this.callback err
          else
            # assert.throws( dup.save, MongoError );
            dup = new Tag
              long:  "whatever"
              short: "!snowflake"
              type:  "problem"
            dup.save (err, tag) ->
              console.log err
              console.log tag
              this.callback
        ###

      "it fails": (err, tag) ->
        assert.isNotNull err
        assert.isNull tag

        #dup = new Tag
        #  long:  "whatever"
        #  short: "!snowflake"
        #  type:  "problem"
        #assert.throws( dup.save, MongoError );
        ###
        console.log "Fails?"
        console.log err
        console.log tag
        assert.notEqual err, null
        ###
)

tagBatch.export module
