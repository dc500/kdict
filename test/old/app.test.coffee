app    = require("../app.coffee")
assert = require("assert")
zombie = require("zombie")
events = require("events")
testHelper = require("./helper")

app.listen 3001

testHelper.models = [ app.User ]

testHelper.setup ->
  user = new app.User(
    username: "ben"
    email: "ben@example.com"
    password: "test"
  )
  user.save (err) ->
    if err
      console.log "ERROR, our fixture couldn't save"
      assert.equal true, false
    testHelper.run exports

testHelper.tests = 
  "test login": ->
    zombie.visit "http://localhost:3001/login", (err, browser, status) ->
      browser.fill("user[email]", "ben@example.com").fill("user[password]", "test").pressButton "Log In", (err, browser, status) ->
        assert.equal err, null
        assert.equal browser.text("a.logout"), "Log Out"
        assert.equal browser.text("li.username"), "ben"
        clickLink "Log Out", (err, browser, status) ->
          assert.equal err, null
          assert.equal browser.text("a.login"), "Login"
        
        testHelper.end()
  
  "test signup": ->
    zombie.visit "http://localhost:3001/signup", (err, browser, status) ->
      browser.fill("user[username]", "foo").fill("user[email]", "foo@example.com").fill("user[password]", "test").pressButton "Sign up", (err, browser, status) ->
        assert.equal browser.text("#menu a.logout"), "Log Out"
        testHelper.end()
  
  "test duplicate detection": ->
    user1 = new app.User(
      username: "benfeh"
      email: "duplicate@example.com"
      password: "test"
    )
    user2 = new app.User(
      username: "benmeh"
      email: "duplicate@example.com"
      password: "test2"
    )
    user1.save (err) ->
      assert.equal err, null
    
    user2.save (err) ->
      assert.notEqual err, null
      testHelper.end()
  
  "test search": ->
    zombie.visit "http://localhost:3001/", (err, browser, status) ->
      browser.fill("q", "cheese").pressButton "search", (err, browser, status) ->
        assert.equal browser.text("#results :first h2"), "치즈"
        testHelper.end()
  
  "test editing": ->
    zombie.visit "http://localhost:3001/entries/4e6314698c2e86434c001185", (err, browser, status) ->
      browser.clickLink "Edit", (err, browser, status) ->
        browser.fill("entry[korean]", "한국어").fill("entry[hanja]", "韓国語").fill("entry[english]", "korean language").pressButton "Save", (err, browser, status) ->
          assert.equal browser.text("h2.korean"), "한국어"
          assert.equal browser.text("p.hanja"), "韓国語"
          assert.equal browser.text(".definitions ul li"), "korean language"
          testHelper.end()


