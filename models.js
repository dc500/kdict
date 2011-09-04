/* Taken from Alex Young's excellent Notepad tutorial */
/* https://raw.github.com/alexyoung/nodepad/master/models.js */

var crypto = require('crypto'),
    Entry,
    User,
    LoginToken;

function defineModels(mongoose, fn) {
    var Schema = mongoose.Schema,
        ObjectId = Schema.ObjectId;


    /**
     * Model: Entry
     */
    Entry = new Schema({
        korean: { 
            word : { type: String, index: true }, // validate: [ validateNonEnglish, 'Korean must not contain English characters'] },
            length : { type: Number },
        },
        hanja: { type: String }, //, validate: [ validateNonEnglish, 'Hanja must not contain English characters'] },
        pos: String,
        
        // TODO this needs to be improved
        definitions : {
            english : [ String ],
        },
        old : {
            submitter : String,
            table     : String,
            wordid    : Number,
        },
        flags: [ String ],
        submitter: ObjectId,
        created_at: { type: Date, default: Date.now },
        updated_at: { type: Date, default: Date.now }
    });

    // TODO Add indices

    Entry.virtual('id')
        .get(function() {
            return this._id.toHexString();
        });

    Entry.pre('save', function(next) {
        // TODO Automatically generate phonetic representation
        next();
    });


    function validateNonEnglish(value) {
        return value =~ /[^a-z]/i;
    }

    function validatePresenceOf(value) {
        console.log("Validating presence of '" + value + "'");
        return value && value.length;
    }

    /**
     * Model: User
     */

    User = new Schema({
        'username': { type: String, validate: [validatePresenceOf, 'a username is required'], index: { unique: true } },
        'email': { type: String, validate: [validatePresenceOf, 'an email is required'], index: { unique: true } },
         'hashed_password': String,
         'salt': String
    });

    User.virtual('id')
        .get(function() {
            return this._id.toHexString();
        });

    User.virtual('password')
        .set(function(password) {
            this._password = password;
            this.salt = this.makeSalt();
            this.hashed_password = this.encryptPassword(password);
        })
    .get(function() { return this._password; });

    User.method('authenticate', function(plainText) {
        return this.encryptPassword(plainText) === this.hashed_password;
    });

    User.method('makeSalt', function() {
        return Math.round((new Date().valueOf() * Math.random())) + '';
    });

    User.method('encryptPassword', function(password) {
        return crypto.createHmac('sha1', this.salt).update(password).digest('hex');
    });

    User.pre('save', function(next) {
        if (!validatePresenceOf(this.password)) {
            console.log("NO PASSWORD");
            next(new Error('Invalid password'));
        } else {
            console.log("Next");
            next();
        }
    });

    /**
     * Model: LoginToken
     * Used for session persistence.
     */
    LoginToken = new Schema({
        email: { type: String, index: true },
               series: { type: String, index: true },
               token: { type: String, index: true }
    });

    LoginToken.method('randomToken', function() {
        return Math.round((new Date().valueOf() * Math.random())) + '';
    });

    LoginToken.pre('save', function(next) {
        // Automatically create the tokens
        this.token = this.randomToken();

        if (this.isNew)
        this.series = this.randomToken();

    next();
    });

    LoginToken.virtual('id')
        .get(function() {
            return this._id.toHexString();
        });

    LoginToken.virtual('cookieValue')
        .get(function() {
            return JSON.stringify({ email: this.email, token: this.token, series: this.series });
        });

    mongoose.model('Entry', Entry);
    mongoose.model('User', User);
    mongoose.model('LoginToken', LoginToken);

    fn();
}

exports.defineModels = defineModels; 



