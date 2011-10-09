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

vows_bdd.Feature("Rollback")
  .scenario("Rolling back a recent change")

  #.given "the server is running", ->
  #  @callback

  .given "the DB is popuplated", ->
    e.single "안녕하세요", "hello", null, @callback

  .when "I visit an entry", ->
    zombie.visit "http://localhost:#{port}/안녕하세요", @callback

  .when "I click the edit link", (err, browser, status) ->
    assert.ok browser.querySelector ":input[name=q]"
    browser.clickLink "Edit", @callback

  .then "I should see an edit form", (browser, status) ->
    assert.ok browser.querySelector ":input[name=entry[hangul]]"

  .when "I submit the form", (err, browser, status) ->
    browser.fill("entry[hangul]", "안녕녕")
           .pressButton "Update", @callback

  .then "The new page should display my changes", (err, browser, status) ->
    assert.equals browser.querySelectorAll("#title"), "안녕영"

  .when "I click rollback", (err, browser, status) ->
    browser.clickLink "Rollback", @callback

  .then "The old title should be displayed", (err, browser, status) ->
    assert.equals browser.querySelectorAll("#title"), "안녕하세요"
  

  .complete()

  
  .finish(module)




