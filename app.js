// Deps
var express = require('express');
var SearchProvider = require('./search').SearchProvider;

var express        = require('express'),
    connect        = require('connect'),
    jade           = require('jade'),
    app            = module.exports = express.createServer(),
    mongoose       = require('mongoose'),
    mongoStore     = require('connect-mongodb'),
    mailer         = require('mailer'),
    stylus         = require('stylus'),
    connectTimeout = require('connect-timeout'),
    sys            = require('sys'),
    path           = require('path'),
    models         = require('./models'),
    fs             = require('fs'),
    step           = require('step'),
    db,
    Entry,
    User,
    //LoginToken,
    Settings = { development: {}, test: {}, production: {} },
    emails;


// Uncomment later
emails = {
  send: function(template, mailOptions, templateOptions) {
    mailOptions.to = mailOptions.to;
    jade.renderFile(path.join(__dirname, 'views', 'mailer', template), templateOptions, function(err, text) {
      // Add the rendered Jade template to the mailOptions
      mailOptions.body = text;

      // Merge the app's mail options
      var keys = Object.keys(app.set('mailOptions')),
          k;
      for (var i = 0, len = keys.length; i < len; i++) {
        k = keys[i];
        if (!mailOptions.hasOwnProperty(k))
          mailOptions[k] = app.set('mailOptions')[k]
      }

      console.log('[SENDING MAIL]', sys.inspect(mailOptions));

      // Only send mails in production
      if (app.settings.env == 'production') {
        mailer.send(mailOptions,
          function(err, result) {
            if (err) {
              console.log(err);
            }
          }
        );
      }
    });
  },

  sendConfirmation: function(user) {
    this.send('confirmation.jade', {
        to: user.email, subject: 'KDict - Please Confirm'
    }, { locals: { user: user } });
  }
};


var app = module.exports = express.createServer();


//new
//var MemStore = require('connect/middleware/session/memory');


// Config
app.configure(function(){
    app.set('views', __dirname + '/views');
    app.set('view engine', 'jade');
    app.use(express.favicon());
    app.use(express.bodyParser());
    app.use(express.cookieParser());
    app.use(connectTimeout({ time: 10000 }));
    app.use(express.session({ store: mongoStore(app.set('db-uri')), secret: 'kingofnopants' }));
    app.use(express.logger({ format: '\x1b[1m:method\x1b[0m \x1b[33m:url\x1b[0m :response-time ms' }))
    app.use(express.methodOverride());
    app.use(stylus.middleware({ src: __dirname + '/public' }));
    app.use(express.static(__dirname + '/public'));


    //new
    //app.use(express.cookieDecoder());
    //app.use(express.session({ store: MemStore( { reapInterval: 60000 * 10 }) });
/*
   app.set('views', __dirname + '/views');
   app.use(express.favicon(__dirname + '/public/favicon.ico'));
   app.use(express.bodyParser());
   app.use(express.methodOverride());
   app.use(require('stylus').middleware({ src: __dirname + '/public' }));
   app.use(app.router);
   app.use(express.static(__dirname + '/public'));
    */
    app.set('mailOptions', {
        host: 'localhost',
        port: '25',
        from: 'signup@kdict.com'
    });
});

app.dynamicHelpers({
    currentUser: function(req, res) {
        return req.session.user;
        return req.currentUser;
    },
    messages: require('express-messages'),
});

// TODO move
function hash(msg, key) {
  return crypto.createHmac('sha256', key).update(msg).digest('hex');
}
function authenticate(email, pass, next) {
    User.findOne({ email: email }, function(err, user) {
        // query the db for the given username
        if (err || !user) return next(new Error('cannot find user'));
        // apply the same algorithm to the POSTed password, applying
        // the hash against the pass / salt, if there is a match we
        // found the user
        if (user.authenticate) return next(null, user);
        //if (user.hashed_password == hash(pass, user.salt)) return next(null, user);
        // Otherwise password is invalid
        next(new Error('invalid password'));
    });
}
function requireLogin(req, res, next) {
    if (req.session.user) {
        next();
    } else {
        req.session.error = 'Access denied!';
        res.redirect('/login');
    }
}




app.configure('development', function(){
    app.set('db-uri', 'mongodb://localhost/kdict');
    app.use(express.logger());
    app.use(express.errorHandler({ dumpExceptions: true, showStack: true })); 
});

app.configure('production', function(){
    app.use(express.logger());
    app.use(express.errorHandler()); 
});

app.configure('test', function() {
    app.use(express.errorHandler({ dumpExceptions: true, showStack: true }));
    db = mongoose.connect('mongodb://localhost/nodepad-test');
});


var searchProvider = new SearchProvider('localhost', 27017);

// Hmm



// Models
models.defineModels(mongoose, function() {
    app.Entry      = Entry      = mongoose.model('Entry');
    app.Update     = Update     = mongoose.model('Update');
    app.User       = User       = mongoose.model('User');
    //app.LoginToken = LoginToken = mongoose.model('LoginToken');
    db = mongoose.connect(app.set('db-uri'));
});


// Routes
function NotFound(msg) {
  this.name = 'NotFound';
  Error.call(this, msg);
  Error.captureStackTrace(this, arguments.callee);
}
app.error(function(err, req, res, next) {
    if (err instanceof NotFound) {
        res.render('404', { status: 404 });
    } else {
        next(err);
    }
});

app.get('/404/?', function(req, res) {
    res.render('404', { status: 404 });
});


app.get('/logout/?', function(req, res){
    // destroy the user's session to log them out
    // will be re-created next request
    req.session.destroy(function(){
        // TODO flash requires sessions
        //req.flash('info', 'Logged out');
        res.redirect('/');
    });
});

app.get('/login/?', function(req, res){
    // already logged in
    if (req.session.user) {
        res.redirect('/');
    }
    res.render('sessions/new', {
        locals: {
            title: 'Login'
        }
    });
});

app.post('/login/?', function(req, res){
    authenticate(req.body.user.email, req.body.user.password, function(err, user) {
        if (user) {
            console.log("Found user");
            // Regenerate session when signing in
            // to prevent fixation 
            req.session.regenerate(function(){
                req.flash('info', 'Logged in');
                console.log("Regenerated session");
                // Store the user's primary key 
                // in the session store to be retrieved,
                // or in this case the entire user object
                req.session.user = user;
                res.redirect('/');
            });
        } else {
            req.flash('error', 'Could not find user');
            console.log("Couldn't find user");
            req.session.error = 'Authentication failed, please check your '
                + ' username and password.'
                + ' (use "tj" and "foobar")';
    res.redirect('back');
        }
    });
});





// Basic searching

app.get('/', function(req, res, next) {
    if (req.param('q')) {
        var pg = parseInt(req.param('pg'));
        var pp = parseInt(req.param('pp'));
        var page     = pg ? pg : 1;
        var per_page = pp ? pp : 20;
        searchProvider.search(
            req.param('q'),
            page,
            per_page,
            function( error, results) {
                res.render('search', {
                    locals: {
                        results: results,
                        q: req.param('q')
                    },
                    title: "'" + req.param('q') + "'"
                });
            }
        );
    } else {
        res.render('index', {
            title: 'Korean dictionary',
            locals: { // hacky
                q: ''
            }
        });
    }
});










////// ENTRY CONTENTS
/*
app.get('/entries/recent', function(req, res) {
    console.log("Displaying recent changes");
    res.render('entries/recent', {
        locals: { entries: }
    });
});
*/

app.get('/entries/new/?', requireLogin, function(req, res) {
    console.log("Displaying new form");
    res.render('entries/new', {
        locals: { entry: new Entry() }
    });
});

// Create Entry
app.post('/entries.:format?', requireLogin, function(req, res) {
    console.log("Trying to create new entry");

    console.log(req.body);

    var entry = new Entry({
        korean: {
            word: req.body.entry.korean,
            length: req.body.entry.korean.length,
        },
        hanja:   req.body.entry.hanja,
        definitions: { 
            english: [
                req.body.entry.english
            ]
        }
    });
    // TODO Doing it the above way until I work out what's going wrong
    //var entry = new Entry(req.body.entry);

    entry.user_id = req.currentUser._id;

    console.log("Saving...");
    console.log(entry);
    entry.save(function(err) {
        if (err) {
            console.log("Save error");
            console.log(err);
        }
        switch (req.params.format) {
            case 'json':
                var data = entry.toObject();
        
                // TODO: Backbone requires 'id', but can I alias it?
                data.id = data._id;
                res.send(data);
                break;

            default:
                req.flash('info', 'Entry created');

                console.log("Entry created");
                res.redirect('/entries/' + entry._id);
        }
    });
});

// Read Entry
app.get('/entries/:id.:format?', function(req, res, next) {

    console.log("Read entry");

    Entry.findOne({ _id: req.params.id }, function(err, entry) {
        if (!entry) return next(new NotFound('Entry not found'));

        console.log("Dumping contents of D baby");
        console.log(entry);

        switch (req.params.format) {
            case 'json':
                res.send(entry.toObject());
                break;

                /*
            case 'html':
                res.send(markdown.toHTML(d.data));
                break;
                */

            default:
                res.render('entries/show', {
                    locals: { entry: entry, currentUser: req.currentUser }
                });
        }
    });
});


// Edit entry
app.get('/entries/:id.:format?/edit', requireLogin, function(req, res, next) {
    console.log("Trying to edit something. Delicious");
    Entry.findOne( { _id: req.params.id }, function(err, entry) {
        if (!entry) return next(new NotFound('Entry not found'));

        console.log("Dumping contents of D baby");
        console.log(entry);

        res.render('entries/edit', {
            locals: { entry: entry, currentUser: req.currentUser }
        });
    });
});


// Update Entry
app.put('/entries/:id.:format?', requireLogin, function(req, res, next) {
    console.log("Trying to update document");

    Entry.findOne({ _id: req.params.id }, function(err, entry) {
        if (err) {
            console.log("Save error");
            console.log(err);
        }
        if (!entry) return next(new NotFound('Entry not found'));

        // Difference between old and new entry

        console.log("------------------------");
        console.log("Trying to update document");
        console.log(entry);

        console.log("------------------------");
        console.log("Req body:");
        console.log(req.body);

        console.log("------------------------");
        console.log("Req params:");
        console.log(req.params);

        var change = {};
        if (entry.korean.word != req.body.entry.korean) {
            change.korean.word   = req.body.entry.korean;
            change.korean.length = req.body.entry.korean.length;
        }

        if (entry.hanja != req.body.entry.hanja) {
            change.hanja = req.body.entry.hanja;
        }

        if (entry.definitions.english != [ req.body.entry.english ]) {
            change.definitions.english = req.body.entry.english;
        }
        // TODO: Add the flupping change

        //entry.hanja                = req.body.entry.hanja;

        console.log("------------------------");
        console.log("Changes:");
        console.log(changes);

        console.log("------------------------");
        console.log("Updated entry:");
        console.log(entry);

        entry.save(function(err) {
            if (err) {
                console.log("Save error");
                console.log(err);
            }
            else {
                // Create Update entry of same contents
                var update = new Update();
                update.change = change;
                update.user_id = currentUser._id;
                update.word_id = entry._id;
                entry.save(function(err) {
                    if (err) {
                        console.log("Save error");
                        console.log(err);
                    }
                });
            }


            switch (req.params.format) {
                case 'json':
                    res.send(entry.toObject());
                    break;

                default:
                    req.flash('info', 'Entry updated');
                    res.redirect('/entries/' + req.params.id );
            }
        });
    });
});

// Delete entry
app.del('/entries/:id.:format?', requireLogin, function(req, res, next) {
    Entry.findOne({ _id: req.params.id }, function(err, d) {
        if (!d) return next(new NotFound('entry not found'));

        d.remove(function() {
            switch (req.params.format) {
                case 'json':
                    res.send('true');
                    break;

                default:
                    req.flash('info', 'entry deleted');
                    res.redirect('/');
            }
        });
    });
});







//////// USER CONTENTS


app.get('/signup/?', function(req, res) {
    res.render('users/new', {
        locals: { user: new User(), title: 'Sign Up' }
    });
});

// Creation
app.post('/users.:format?', function(req, res) {
    var user = new User(req.body.user);

    function userSaveFailed() {
        console.log('Save failed')
        req.flash('error', 'Account creation failed');
        res.render('users/new', {
            locals: { user: user }
        });
    }

    user.save(function(err) {
        if (err) {
            console.log(err);
            return userSaveFailed();
        }


        console.log('Save complete');
        emails.sendConfirmation(user);

        // TODO
        req.flash('info', 'Your account has been created');
        //emails.sendWelcome(user);

        switch (req.params.format) {
            case 'json':
                res.send(user.toObject());
                break;

            default:
                req.session.user_id = user.id;
                res.redirect('/');
        }
    });
});





// /files/* is accessed via req.params[0]
// but here we name it :file
app.get('/data/:file(*)', function(req, res, next){
  var file = req.params.file
    , path = __dirname + '/data/' + file;
  // either res.download(path) and let
  // express handle failures, or provide
  // a callback as shown below
  res.download(path, function(err){
    // if an error occurs in this callback
    // the file most likely does not exist,
    // and it's safe to respond or next(err)
    if (err) return next(err);

    // the file has been transferred, do not respond
    // from here, though you may use this callback
    // for stats etc.
    console.log('transferred %s', path);
  }, function(err){
    // this second optional callback is used when
    // an error occurs during transmission
  });
});

app.use(function(err, req, res, next){
  if ('ENOENT' == err.code) {
      // TODO not sure if this is the best way
      //res.redirect('404');
      throw new NotFound;
      //res.send('Cant find that file, sorry!');
  } else {
    // Not a 404
    next(err);
  }
});






// Dumb stuff
app.get('/about/?', function(req, res){
    res.render('about', {
        title: 'About'
    });
});
app.get('/contribute/?', function(req, res){
    res.render('help', { // TODO Change filename to contribute
        title: 'Contribute'
    });
});




function getFileDetails(filename, callback) {
    fs.stat(filename, function(err, stat) {
        if (err) {
            if (err.errno === process.ENOENT) {
                return callback(null, 0);
            }
            return callback(err);
        }
        // Return the info we care about
        callback(null, [ stat.size, stat.mtime, stat.ctime ]);
    });
}

/*
function getFiles(directory) {
    var files = [];
    var p = path.join(__dirname, directory);
    fs.readdir(p, function(err, files) {
        console.log(files);
        files.forEach(function (filename) {
            console.log(filename);
            fs.stat(path.join(p, filename), function(info) {
                console.log(info);
                files.push(info);
            });
        });
        return files;
    });
    console.log(files);
}
*/


// Want to get a list of files and their details
var getFiles = step.fn(
    function readDir(directory) {
        var p = path.join(__dirname, directory);
        fs.readdir(p, this);
    },
    function readFiles(err, results) {
        if (err) throw err;
        var files = [];

        // TODO make asynchronous
        //var group = this.group();
        //results.forEach(function (filename) {

        for (var i = 0; i < results.length; i++) {
            var filename = results[i];
            var p = path.join(__dirname, 'data', filename);
            
            // TODO make asynchronous
            var stats = fs.statSync(p);

            files.push( { name: filename, size: getTextFilesize(stats.size) } );
        }
        return files;
    }
);

function getTextFilesize(bits) {
    var mb = (bits / (1024*1024)).toFixed(2);
    var kb = (bits / (1024)).toFixed(2);
    var filesize = "";
    if (Math.floor(mb) != 0) {
        filesize = mb + " MB";
    } else {
        filesize = kb + " kB";
    }
    return filesize;
}

app.get('/download/?', function(req, res){

    // file format-
    // yyyy-mm-dd.format

    // Step stuff based on http://refactormycode.com/codes/1420-node-js-calculating-total-filesize-of-3-files
    getFiles('data', function(err, files) {
        console.log("Files baby");
        console.log(files);
        res.render('download', {
            title: 'Download',
            files: files,
        });
    });
});





// Final catch-all
app.get('*', function(req, res){
    res.render('404', { status: 404 });
});

// Startup
if (!module.parent) {
    app.listen(3000);
    console.log('Express server listening on port %d, environment: %s', app.address().port, app.settings.env)
    console.log('Using connect %s, Express %s, Jade %s', connect.version, express.version, jade.version);
}

