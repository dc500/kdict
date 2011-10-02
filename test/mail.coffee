vows   = require "vows"
assert = require "assert"
mail   = require "../lib/mail"

vows.describe("Mail").addBatch(
  "A test email":
    "with normal content":
      topic: ->
        options =
          to: "benhumphreys@gmail.com"
          subject: "sup"
          body: "hey it's me"
        mail.send options, @callback

      "should send correctly": (err, results) ->
        assert.isNull    err
        assert.isNotNull results
).export module

