/**
 * Run with expresso test/app.test.js
 */
// TODO: This is really messy
//       There MUST be a nicer way of doing testing
// TODO: Maybe convert this to use Capybara-zombie?

var //coffee     = require('coffeescript'),
    app        = require('../app.coffee'),
    assert     = require('assert'),
    zombie     = require('zombie'),
    events     = require('events'),
    testHelper = require('./helper');

app.listen(3001);

testHelper.models = [app.User];

testHelper.setup(function() {
    // Fixtures
    var user = new app.User({
        'username': 'ben',
        'email':    'ben@example.com',
        'password': 'test'
    });
    user.save(function(err) {
        if (err) {
            console.log("ERROR, our fixture couldn't save");
            assert.equal(true, false);
        }
        testHelper.run(exports)
    });
});


testHelper.tests = {
    'test login': function() {
        zombie.visit('http://localhost:3001/login', function(err, browser, status) {
            // Fill email, password and submit form
            browser.
            fill('user[email]', 'ben@example.com').
            fill('user[password]', 'test').
            pressButton('Log In', function(err, browser, status) {
                assert.equal(err, null);
                // Form submitted, new page loaded.
                //assert.equal(browser.body.querySelector('a.logout'), 'Log Out');
                assert.equal(browser.text('a.logout'), 'Log Out');
                assert.equal(browser.text('li.username'), 'ben');
                clickLink("Log Out", function( err, browser, status) {
                    assert.equal(err, null);
                    assert.equal(browser.text('a.login'), 'Login');
                });
                testHelper.end();
            });
        });
    },

    'test signup': function() {
        zombie.visit('http://localhost:3001/signup', function(err, browser, status) {
            // Fill email, password and submit form
            browser.
            fill('user[username]', 'foo').
            fill('user[email]',    'foo@example.com').
            fill('user[password]', 'test').
            pressButton('Sign up', function(err, browser, status) {
                // Form submitted, new page loaded.
                assert.equal(browser.text('#menu a.logout'), 'Log Out');
                testHelper.end();
            });
        });
    },

    'test duplicate detection': function() {
        var user1 = new app.User({
            'username': 'benfeh',
            'email':    'duplicate@example.com',
            'password': 'test'
        });
        var user2 = new app.User({
            'username': 'benmeh',
            'email':    'duplicate@example.com',
            'password': 'test2'
        });
        user1.save(function(err) {
            // Make sure an error was thrown
            assert.equal(err, null);
        });
        user2.save(function(err) {
            // Make sure an error was thrown
            assert.notEqual(err, null);
            testHelper.end();
        });
    },

    'test search': function() {
        zombie.visit('http://localhost:3001/', function(err, browser, status) {
            // Fill email, password and submit form
            browser.
            fill('q', 'cheese').
            pressButton('search', function(err, browser, status) {
                // Form submitted, new page loaded.
                assert.equal(browser.text('#results :first h2'), '치즈');
                testHelper.end();
            });
        });
    },

    // Require login first
    'test editing': function() {
        // Edit cheese
        zombie.visit('http://localhost:3001/entries/4e6314698c2e86434c001185', function(err, browser, status) {
            browser.
            clickLink("Edit", function( err, browser, status) {
                browser.
                fill('entry[korean]',  '한국어').
                fill('entry[hanja]',   '韓国語').
                fill('entry[english]', 'korean language').
                pressButton('Save', function(err, browser, status) {
                    // Form submitted, new page loaded.
                    assert.equal(browser.text('h2.korean'), '한국어');
                    assert.equal(browser.text('p.hanja'), '韓国語');
                    assert.equal(browser.text('.definitions ul li'), 'korean language');
                    testHelper.end();
                });
            });
        });
    }
};

