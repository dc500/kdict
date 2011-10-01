crypto = require("crypto")

defineModel = (mongoose, fn) ->
  Schema = mongoose.Schema

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
  User.path("username").validate(valUsername, "Username must be between 4 and 20 characters, and only contain alphabetical characters and _")

  valPassword = (value) ->
    value.length >= 6 and
      value.length <= 64 and
      value != @password
  ##User.path("password").validate(valPassword, "Password must be at least 6 characters")

  valEmail = (value) ->
    value.match /^.+@.+$/
  User.path("email").validate(valEmail, "Email doesn't look right...")

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
      return "edit"
    else if @score > 100
      return "something"
    else
      return "normal"

  User.method "makeSalt", ->
    Math.round((new Date().valueOf() * Math.random())) + ""

  User.method "authenticate", (plainText) ->
    @encryptPassword(plainText) == @hashed_password

  User.method "encryptPassword", (password) ->
    crypto.createHmac("sha256", @salt).update(password).digest "hex"

  User.pre "save", (next) ->
    unless valPassword(@password)
      next new Error("Invalid password")
    else
      console.log "Next"
      next()

  mongoose.model "User",  User
  fn()

exports.defineModel = defineModel

