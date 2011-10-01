zombie = require "zombie"
assert = require "assert"
app    = require "../../app"
vows_bdd = require "vows-bdd"

port = 3001
app.listen port

vows_bdd.Feature("Creating a User")
  .scenario("Create a User via Form")

  #.given "the server is running", ->
  #  app.listen(port)
  #  @callback

  #.and "the DB is popuplated", ->
  #  setupFixtures @callback

  .when "I visit the form at user/new", ->
    zombie.visit "http://localhost:#{port}/signup", @callback

  .then "I should see a username field", (err, browser, status) ->
    assert.ok browser.querySelector ":input[name=user[username]]"

  .and "I should see an email entry", (err, browser, status) ->
    assert.ok browser.querySelector, ":input[name=user[email]]"

  .and "I should see a password entry", (err, browser, status) ->
    assert.ok browser.querySelector, ":input[name=user[password]]"

  .and "I should see a password confirmation", (err, browser, status) ->
    assert.ok browser.querySelector, ":input[name=user[confirmPassword]]"

  .when "I submit the form", (browser, status) ->
    browser.fill("user[username]",        "test")
           .fill("user[email]",           "foo@beans.com")
           .fill("user[password]",        "foobar")
           .fill("user[confirmPassword]", "foobar")
           .pressButton "Sign up", @callback

  .then "a new User should be created", (err, browser, status) ->
    assert.ok findNewUser()

  .complete()

  
  .finish(module)


