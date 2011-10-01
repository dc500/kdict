vows     = require "vows"
assert   = require "assert"
mongoose = require "mongoose"
user      = require "../models/user"

db_uri = "mongodb://localhost/kdict_test"
db = mongoose.connect(db_uri)

user.defineModel mongoose, ->
  

user = mongoose.model("user")

# Drop users
User.collection.drop()

userBatch = vows.describe("user").addBatch(
  "A user":
    "when creating perfect user":
      topic: ->
        person = new User
          username: "jimbo"
          display_name: "hello there"
          email: "what@hello.com"
          score: 0

        person.save this.callback
      
      "it succeeds": (err, user) ->
        assert.equal err, null
)

userBatch.export module

