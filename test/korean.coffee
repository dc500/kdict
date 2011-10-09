vows     = require "vows"
assert   = require "assert"
korean   = require '../public/javascripts/korean.js'

vows.describe("Korean").addBatch(
  "Korean language detection":
    "with english word":
      topic: korean.detect_characters("cheesecake")
      "should be detected": (topic) ->
        assert.equal topic, "english"

    "with korean word":
      topic: korean.detect_characters("한국어")
      "should be detected": (topic) ->
        assert.equal topic, "hangul"

    "with hanja word":
      topic: korean.detect_characters("韓國")
      "should be detected": (topic) ->
        assert.equal topic, "hanja"

    "with mixed word":
      topic: korean.detect_characters("cheesecake 한")
      "should be detected": (topic) ->
        assert.equal topic, "mixed"

  "Korean boolean":
    "with english word and english acceptance":
      topic: korean.is_type("cheesecake",
        english: true)
      "should return true": (topic) ->
        assert.equal topic, true

    "with english word and non-english acceptance":
      topic: korean.is_type("cheesecake",
        hangul: true)
      "should return false": (topic) ->
        assert.equal topic, false

    "with hanja and hangul mix":
      topic: korean.is_type("韓國한국",
        hangul: true
        hanja:  true
      )
      "should return true": (topic) ->
        assert.equal topic, true

).export module

