ktools = require("../public/javascripts/korean.js")

mongoose = require "mongoose"
update   = require "../models/update"
update.defineModel mongoose, ->
  
Update = mongoose.model("Update")


# TODO: Abstract this validation out to a seperate module to be used in interface
#       code
valHangul = (value) ->
  return ktools.detect_characters(value) == "hangul"

valAlphanumeric = (values) ->
  console.log "Validating English"
  console.log values
  for val in values
    if ktools.detect_characters(val) != "english"
      return false
  return true

valHanja = (values) ->
  console.log "Validating hanja"
  console.log values
  for val in values
    if ktools.detect_characters(val) != "hanja"
      return false
  return true

valPOS = (value) ->
  true

trim = (value) ->
  if Array.isArray(value)
    for val in value
      val = _trim(val)
    return value
  else
    return _trim(value)
  return value

_trim = (value) ->
  return value.replace(/^\s+|\s+$/g, "")


fail = (value) ->
  return false

defineModel = (mongoose, fn) ->
  Schema = mongoose.Schema

  # Bundles up all data for a single "meaning" thinking from the Korean perspective
  Sense = new Schema(
    hanja:
      type: [ String ]
      validate: [ valHanja, "Hanja must only contain Chinese (Hanja) characters" ]
      index: true
      set: trim
    pos:
      type: String
      validate: [ valPOS, "POS must be one of a list of approved part of speech tags" ]

    definitions:
      english:
        type: [ String ]
        #validate: [ fail, "English must only contain alphanumeric characters" ]
        validate: [ valAlphanumeric, "English must only contain alphanumeric characters" ]
        index: true
        required: true
    related:
      type: [ String ]
      # TODO Optional
      #validate: [ valHangul, "Related words must only contain Hangul characters" ]

    legacy:
      submitter: String
      table:     String
      wordid:    Number
  )
  Sense.virtual("id").get ->
    @_id.toHexString()

  #Sense.path("hanja").set (list) ->
  #  out_list = []
  #  for val in list
  #    out_list.push val.replace(/^\s+|\s+$/g, "")
  #  return out_list

  Sense.path("definitions.english").set (list) ->
    out_list = []
    for val in list
      out_list.push val.replace(/^\s+|\s+$/g, "")
    return out_list

  #Sense.path("definitions.english").validate (val) ->
  #  console.log "Validating Englishsssshshs"
  #  console.log val
  #  return false

    


  Sense.virtual("definitions.english_all").get ->
    console.log @definitions.english
    @definitions.english.join("; ")

  Sense.virtual("definitions.english_all").set (list) ->
    # TODO What about removing whitespace and all that junk
    console.log "List:"
    console.log list
    if list
      @definitions.english = list.split(";")

  Sense.virtual("hanja_all").get ->
    @hanja.join("; ")
  Sense.virtual("hanja_all").set (list) ->
    # TODO What about removing whitespace and all that junk
    if list
      @hanja = list.split(";")



  Entry = new Schema(
    korean:
      hangul:
        type: String
        required: true
        index:
          unique: true
        validate: [ valHangul, "Hangul must only contain Hangul characters" ]

      hangul_length: # But what about the fact that JS has a length function
        type: Number
        #required: true
        index: true
        min: 1
      # TODO Phonetic stuff
      # TODO: mr: { type: String, index: false, validate: [ valAlphabet, "McCune-Reischauer must only contain alphabetic characters" },
      # TODO: yale: { type: String, index: false, validate: [ valAlphabet, "Yale must only contain alphabetic characters" },
      # TODO: rr: { type: String, index: false, validate: [ valAlphabet, "Revised Romanization must only contain alphabetic characters" },
      # TODO: ipa: { type: String, index: false, validate: [ valIPA, "IPA must only contain IPA characters" },
      # TODO: simplified // our hacky thing

    senses: [ Sense ]

    # More general-use, users able to set
    tags:
      type: [ Schema.ObjectId ]
      index:  true
      ref:    "Tag"

    # NEW: Not sure if this is overkill on data duplication
    updates:
      type: [ Schema.ObjectId ]
      #index: true
      ref:  "Update"
  )

  Entry.virtual("id").get ->
    @_id.toHexString()

  Entry.path("korean.hangul").set (hangul) ->
    @korean.hangul_length = hangul.length
    return trim(hangul)

  Entry.pre "save", (next) ->
    # TODO Automatically generate phonetic representation
    # TODO Automatically create Update
    # TODO Increment revision count
    console.log "PRE SAVE IN THEORY"

    # Only create delta Update if this is an update with non-update content
    change = @_delta()
    if change
      console.log "DELTA"
      console.log change

      context = this
      console.log "1 foo"

      update = new Update
        user:   @id #'todo'
        entry:  @id
        before: {} #change['$set']
        after:  {}
        type:   "new"
      update.save (err, saved) ->
        console.log "2 foo"
        if err
          console.log "foo"
          console.log "Save error"
          console.log err
        else
          console.log "foo"
          # TODO actually saving. But this would make a recursive loop, generating an update
          #      in order to actually set the update
          console.log "Saved update! This:"
          console.log saved
          console.log context.updates.push saved.id
          context.save (err2, mod) ->
            console.log "Added update"
            console.log err2
            console.log mod
        next()

    else
      next()

  mongoose.model "Entry", Entry
  fn()

exports.defineModel = defineModel

