Korean   = require("../public/javascripts/korean.js")
mongoose = require('mongoose')
Tag      = mongoose.model('Tag')

Object.extend = (destination, source) ->
  for property of source
    if source.hasOwnProperty(property)
      destination[property] = source[property];
  return destination;

# exporting to test
exports.parseQ = (text) ->
  return if not text or text.match /^\s*$/

  words = text.split(" ")

  query  = {}
  for i of words
    word = words[i]
    console.log "Checking " + word

    switch word.charAt(0)
      when '!', '#' then keyval = this.parseTag(word)
      #when '@' then     keyval = this.parseUser(word)
      when '.' then      keyval = this.parsePOS(word)
      else               keyval = this.parseText(word)

    console.log "Keyval results: "
    console.log keyval
    # merge results
    query = Object.extend(query, keyval)
  
  return query


exports.parseTag = (word) ->
  short = word.substr(1, word.length - 1)
  switch word.charAt(0)
    when '!' then type = 'problem'
    when '#' then type = 'user'
  Tag.findOne( { 'short' : short, 'type' : type } ).run (err, tag) ->
    if (err || !tag)
      console.log "WHAT"
      return { 'hello' : 'there' }
    else
      console.log "CHEESE"
      return { 'tags' : [ tag._id ] }

exports.parsePOS = (word) ->
  without_dot = word.substr(1, word.length - 1)
  return { 'senses.pos' : without_dot }

exports.parseText = (word) ->
  val = new RegExp(word, 'i')
  switch Korean.detect_characters(word)
    when 'hangul'  then return { 'korean.hangul' : val }
    when 'english' then return { 'senses.definitions.english' : val }
    when 'hanja'   then return { 'senses.hanja' : val }


