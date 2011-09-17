# Taken from Alex Young's excellent Notepad tutorial */
# https://raw.github.com/alexyoung/nodepad/master/models.js */
#
#
# Post-process stuff to do
# Define length
# Define phonetic representations
# validate hangul, add flag
# validate hanja, add flag
# validate english, add flag
# validate presence of def, add flag

crypto = require("crypto")

# TODO: Move all this validation to something callable externally
#       So we can have jQuery client-side validation for instant feedback


korean = require("./public/javascripts/korean.js")

valHangul = (value) ->
  return korean.detect_characters(value) == 'hangul'

valAlphanumeric = (value) ->
  return korean.detect_characters(value) == 'english'

valHanja = (value) ->
  return korean.detect_characters(value) == 'hanja'

valPresenceOf = (value) ->
  value and value.length

valPOS = (value) ->
  true

valAndLabel = (entry) ->
  entry.flags.push('bad hangul')  unless valHangul(entry.korean.hangul)
  entry.flags.push('bad English') unless valEnglish(entry.definitions.english[0])

  flag = null
  for hanja in entry.hanja
    if !valHanja(hanja)
      flag = 'bad_hanja'
      break
  if flag
    entry.flags.push(flag)

  entry.flags.push('bad hanja')   unless valHanja(entry.hanja)
  entry.save()



defineModels = (mongoose, fn) ->
  Schema = mongoose.Schema
  ObjectId = Schema.ObjectId



  Entry = new Schema(
    korean:
      hangul:
        type: String
        required: true
        validate: [ valHangul, "Korean must not contain English characters" ]

      length:
        type: Number
        required: true
        index: true
      # TODO Phonetic stuff
      # TODO: mr: { type: String, index: false, validate: [ valAlphabet, 'McCune-Reischauer must only contain alphabetic characters' },
      # TODO: yale: { type: String, index: false, validate: [ valAlphabet, 'Yale must only contain alphabetic characters' },
      # TODO: rr: { type: String, index: false, validate: [ valAlphabet, 'Revised Romanization must only contain alphabetic characters' },
      # TODO: ipa: { type: String, index: false, validate: [ valIPA, 'IPA must only contain IPA characters' },
      # TODO: simplified // our hacky thing

    hanja: [
      type: String
      validate: [ valHanja, "Hanja must only contain Chinese (Hanja) characters" ]
      index: true
    ]
    pos:
      type: String
      validate: [ valPOS, "POS must be one of a list of approved part of speech tags" ]

    definitions:
      english: [
        type: String
        validate: [ valAlphanumeric, "English must only contain alphanumeric characters" ]
        index: true
      ]
    related:
      type: [ String ]
      validate: [ valHangul, "Related words must only contain Hangul characters" ]

    legacy:
      submitter: String
      table: String
      wordid: Number

    revision:
      type: Number
      default: 1
      required: true

    flags: [ type: String ]
    tags: [
      type: String
      index: true
      sparse: true
    ]
  )
  Entry.virtual("id").get ->
    @_id.toHexString()

  Entry.virtual("definitions.english_all").get ->
    @definitions.english.join('; ')
  Entry.virtual("definitions.english_all").set (list) ->
    @definitions.english.list.split('; ')

      

  Entry.pre "save", (next) ->
    # TODO Automatically generate phonetic representation
    # TODO Automatically create Update
    # TODO Increment revision count
    korean.length = korean.hangul.length
    korean.revision = korean.revision + 1
    next()



  Update = new Schema(
    entry:
      type: ObjectId
      index: true
      required: true
      ref: "Entry"

    user:
      type:     ObjectId
      index:    true
      required: true
      ref:      "User"

    before:
      type: Schema.Types.Mixed
      required: true

    after:
      type: Schema.Types.Mixed
      required: true

    type:
      type: String
      enum: [ "new", "edit", "delete" ]

    revision_num:
      type: Number
      required: true
      default: 1

    created_at:
      type: Date
      default: Date.now
      required: true
  )


  User = new Schema(
    display_name:
      type: String

    username:
      type: String
      index: unique: true

    email:
      type: String
      index: unique: true

    score:
      type: Number
      default: 0

    reset_code:
      type: String

    hashed_password: String
    salt: String
  )

  valUsername = (value) ->
    value.match /^[a-z0-9_]{4,20}$/
  User.path('username').validate(valUsername, 'Username must be between 4 and 20 characters, and only contain alphabetical characters and _')

  valPassword = (value) ->
    value.length >= 6 and value.length <= 64
  ##User.path('password').validate(valPassword, 'Password must be at least 6 characters')

  valEmail = (value) ->
    value.match /^.+@.+$/
  User.path('email').validate(valEmail, "Email doesn't look right...")

  User.virtual("id").get ->
    @_id.toHexString()

  User.virtual("password").set (password) ->
    @_password = password
    @salt = @makeSalt()
    @hashed_password = @encryptPassword(password)
  User.virtual("password").get ->
    @_password

  User.virtual("level").get ->
    if @score > 1000
      return 'edit'
    else if @score > 100
      return 'something'
    else
      return 'normal'

  User.method "makeSalt", ->
    Math.round((new Date().valueOf() * Math.random())) + ""

  User.method "authenticate", (plainText) ->
    @encryptPassword(plainText) == @hashed_password

  User.method "encryptPassword", (password) ->
    crypto.createHmac("sha256", @salt).update(password).digest "hex"

  User.pre "save", (next) ->
    unless valPresenceOf(@password)
      console.log "NO PASSWORD"
      next new Error("Invalid password")
    else
      console.log "Next"
      next()



  mongoose.model "Entry",  Entry
  mongoose.model "Update", Update
  mongoose.model "User",   User
  fn()



exports.defineModels = defineModels
