vows     = require "vows"
assert   = require "assert"
mongoose = require "mongoose"
entry    = require "../models/entry"

db_uri = "mongodb://localhost/kdict_test"
db = mongoose.connect(db_uri)
entry.defineModel mongoose, ->
  

Entry = mongoose.model("Entry")
# Drop users
Entry.collection.drop()

# Magical macro
model =
  single: (hangul, english, hanja) ->
    ->
      if not Array.isArray(english)
        english = [ english ]
      entry = new Entry
        korean:
          hangul: hangul
        senses: [
          definitions:
            english: english
        ]
      if hanja
        if not Array.isArray(hanja)
          hanja = [ hanja ]
        entry.hanja = hanja
      entry.save @callback
 
assertPropErr = (prop) ->
  (err, entry) ->
    console.log err
    console.log entry
    assert.isNull    entry
    assert.isNotNull err
    assert.isNotNull err.errors[prop]


entryBatch = vows.describe("Entry").addBatch(
  "An entry":
    "with valid korean word":
      topic: model.single("한국어", "cheese")
      "has korean length same as hangul": (err, entry) ->
        assert.isNull err
        assert.equal entry.korean.hangul, "한국어"
        assert.equal entry.korean.hangul_length, 3

    "with spaces in raw input":
      topic: model.single("  안녕하세요 ", " cheese  ")
      "have final inputs with trimmed spaces": (err, entry) ->
        assert.isNull err
        assert.equal entry.korean.hangul, "안녕하세요"
        assert.equal entry.senses[0].definitions.english[0], "cheese"

    "with non-hangul in hangul":
      topic: model.single("what", "yeah")
      "should error on save": assertPropErr("korean.hangul")

    "with non-English in English":
      topic: model.single("영어", "영어")
      "should error on save": assertPropErr("senses.definitions.english")

    "with non-hanja in hanja":
      topic: model.single("하핳하", "boo", "meh")
      "should error on save": assertPropErr("senses.hanja")
)

entryBatch.export module
