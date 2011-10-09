zombie = require "zombie"
assert = require "assert"
app    = require "../app"
vows_bdd = require "vows-bdd"
mongoose = require "mongoose"
entry    = require "../models/entry"
e        = require "./entry-helper"

port = 3001
app.listen port
# TODO Set something so the DB is set up to use kdict_test
#db_uri = "mongodb://localhost/kdict_test"
#db = mongoose.connect(db_uri)
#entry.defineModel mongoose, -> 
Entry  = mongoose.model("Entry")
#Entry.collection.drop() # You just dropped the production DB. Congratulations

vows_bdd.Feature("Searching")
  .scenario("Basic search")

  #.given "the server is running", ->
  #  @callback

  .given "the DB is popuplated", ->
    e.single "안녕하세요", "hello", null, @callback

  .when "I visit the front page", ->
    zombie.visit "http://localhost:#{port}/", @callback

  .then "I should see a search field", (err, browser, status) ->
    assert.ok browser.querySelector ":input[name=q]"

  .when "I submit the form", (browser, status) ->
    browser.fill("q",        "hello")
           .pressButton "Search", @callback

  .then "The results page should contain results", (err, browser, status) ->
    assert.equals status, 200

  .complete()

  
  .finish(module)



