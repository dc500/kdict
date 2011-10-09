ktools = require("../public/javascripts/korean.js")

mongoose = require "mongoose"
update   = require "../models/update"
update.defineModel mongoose, ->
  
Update = mongoose.model("Update")
Tag    = mongoose.model("Update")


# TODO: Abstract this validation out to a seperate module to be used in interface
#       code
valHangul = (value) ->
  return ktools.is_type(value, { space: true, number: true, hangul: true })

valAlphanumeric = (values) ->
  for val in values
    if !ktools.is_type(val, { space: true, number: true, english: true })
      return false
  return true

valHanja = (values) ->
  for val in values
    if !ktools.is_type(val, { hanja: true })
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
    @definitions.english.join("; ")

  Sense.virtual("definitions.english_all").set (list) ->
    # TODO What about removing whitespace and all that junk
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
    tags: [
      type:  Schema.ObjectId
      index: true
      ref:   "Tag"
    ]

    # NEW: Not sure if this is overkill on data duplication
    revision:
      type:    Number
      min:     0
      default: 0
    #updates: [
    #  type: Schema.ObjectId
    #  #index: true
    #  ref:  "Update"
    #]
  )

  Entry.virtual("id").get ->
    @_id.toHexString()

  Entry.path("korean.hangul").set (hangul) ->
    @korean.hangul_length = hangul.length
    return trim(hangul)

  Entry.pre "save", (next) ->
    #context = this
    # TODO Automatically generate phonetic representation

    @revision = @revision + 1 # starts at 0

    # Only create delta Update if this is an update with non-update content
    #change = @_delta()
    #save_delta(change)
    #save_entire_record(this)

    next()

  Entry.post "save", () ->
    #console.log "Post save"
    #console.log next
    #console.log foo
    if @revision == 1
      type = "new"
    else
      type = "edit"

    update = new Update
      user:    @id # TODO change
      entry:   @id
      type:    type
      content: this
    update.save (err, up) ->
      #next()
      #  context.updates.push up.id

  mongoose.model "Entry", Entry
  fn()

###
save_delta = (change) ->
  if change
    context = this

    new_change = {}
    new_change["set"] = {}
    for key, val of change["$set"]
      console.log key
      #val = change["set"][key]
      new_key = key.replace(/\./g, ",")
      new_change["set"][new_key] = val
    console.log new_change

    update = new Update
      user:   @id #'todo'
      entry:  @id
      before: new_change
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
###

exports.defineModel = defineModel

