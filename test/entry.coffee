vows     = require "vows"
assert   = require "assert"
mongoose = require "mongoose"
entry    = require "../models/entry"
helpers  = require "./helpers"

db_uri = "mongodb://localhost/kdict_test"
db = mongoose.connect(db_uri)
entry.defineModel mongoose, ->
  
Entry = mongoose.model("Entry")
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
        entry.senses[0].hanja = hanja
        console.log "HANJA BABY"
        console.log entry
      entry.save @callback


vows.describe("Entry").addBatch(
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
      "should error on save": helpers.assertPropErr("korean.hangul")

    "with non-English in English":
      topic: model.single("영어", "영어")
      "should error on save": helpers.assertPropErr("definitions.english") # Because part of Senses model

    "with non-hanja in hanja":
      topic: model.single("하핳하", "boo", "meh")
      "should error on save": helpers.assertPropErr("definitions.hanja") # Because part of Senses model

    "with english_all attribute":
      topic: ->
        console.log "Creating"
        entry = new Entry
          korean:
            hangul: "헴"
          senses: [
            definitions:
              english_all: "ham; spam"
          ]
        entry.save this.callback
      "should error on save": (err, entry) ->
        assert.deepEqual entry.senses[0].definitions.english, [ "ham", "spam" ]

  "Another entry":
    "when created":
      topic: model.single("영국", "England")
      "should have an update record": (err, entry) ->
        assert.length entry.updates, 1
        #assert.deepEqual


    "when updated":
      topic: ->
        console.log "Creating"
        entry = new Entry
          korean:
            hangul: "영국인"
          senses: [
            definitions:
              english: [ "Brit" ]
          ]
        local_callback = @callback
        entry.save (err, saved) ->
          console.log "Saved!"
          console.log saved
          saved.korean.hangul = "영영영국"
          saved.senses[0].definitions.english_all = "limey"
          saved.save local_callback

      "should have two update records": (err, entry) ->
        console.log "Saved!"
        assert.length entry.updates, 2
        assert.equal entry.korean.hangul_length, 4

).export module
