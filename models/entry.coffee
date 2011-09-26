korean = require("../public/javascripts/korean.js")

# TODO: Abstract this validation out to a seperate module to be used in interface
#       code
valHangul = (value) ->
  return korean.detect_characters(value) == 'hangul'

valAlphanumeric = (value) ->
  return korean.detect_characters(value) == 'english'

valHanja = (value) ->
  return korean.detect_characters(value) == 'hanja'

valPOS = (value) ->
  true

defineModel = (mongoose, fn) ->
  Schema = mongoose.Schema

  # Bundles up all data for a single 'meaning' thinking from the Korean perspective
  Sense = new Schema(
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
      table:     String
      wordid:    Number
  )
  Sense.virtual("id").get ->
    @_id.toHexString()

  Sense.virtual("definitions.english_all").get ->
    @definitions.english.join('; ')
  Sense.virtual("definitions.english_all").set (list) ->
    @definitions.english.list.split('; ')



  Entry = new Schema(
    korean:
      hangul:
        type: String
        required: true
        index:
          unique: true
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

    senses: [ Sense ]

    # More general-use, users able to set
    tags: [
      type:   Schema.ObjectId
      index:  true
      ref:    "Tag"
    ]

    # NEW: Not sure if this is overkill on data duplication
    updates: [
      type: Schema.ObjectId
      #index: true
      ref:  "Update"
    ]
  )

  Entry.virtual("id").get ->
    @_id.toHexString()

  Entry.pre "save", (next) ->
    # TODO Automatically generate phonetic representation
    # TODO Automatically create Update
    # TODO Increment revision count
    korean.length = korean.hangul.length
    korean.revision = korean.revision + 1
    next()

  mongoose.model "Entry", Entry
  fn()

exports.defineModel = defineModel

