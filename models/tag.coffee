valPrefixChar = (short_word) ->
  switch short_word.charAt(0)
    when '!'
      return @type == 'problem'
    when '#'
      return @type == 'user'
    else
      return false

defineModel = (mongoose, next) ->
  Schema = mongoose.Schema

  Tag = new Schema(
    long: String
    short:
      type: String
      index:
        unique: true
      required: true
      validate: [ valPrefixChar, "Prefix character must exist and match tag type" ]
      # TODO: Validation that prefix must match type
      #validate: [ valUnique, 'moo' ]
      ###
      (v) ->
          valPrefixChar(v) && valUnique(v)
        'composite']
      ###
      
    type:
      type:     String
      enum:     [ "problem", "user" ]
      required: true
  )

  #Tag.path("short").validate (short_word) ->
  #  console.log "Validating uniqueness of " + short_word
  #  self.findOne( { "short": short_word } ) (err, word) ->
  #    if (word)
  #      return false
  #    else
  #      return true

  mongoose.model "Tag", Tag
  next()

exports.defineModel = defineModel
