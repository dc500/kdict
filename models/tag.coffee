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
      
    type:
      type:     String
      enum:     [ "problem", "user" ]
      required: true
  )

  mongoose.model "Tag", Tag
  next()

exports.defineModel = defineModel
