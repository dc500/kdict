assert   = require 'assert'
mongoose = require('mongoose')
tag            = require("../models/tag")
#url            = require('url') # for pagination
#qs             = require('querystring')
#mongoose       = require('mongoose')
#entry          = require("../models/entry")
#entry.defineModel(mongoose)
##update         = require("../models/update")
#tag            = require("../models/tag")
##user           = require("../models/user")
#Entry    = mongoose.model('Entry')
##Tag      = mongoose.model('Tag')
##Korean   = require("../public/javascripts/korean.js")
##Search   = require("../public/javascripts/search.js")
#mongoose = require('mongoose')
tag.defineModel mongoose, ->
  console.log "Done"
  db = mongoose.connect('mongodb://localhost/kdict')
#entry    = require("../models/entry")
#entry.defineModel mongoose, ->
#  entry    = require("../models/entry")
#  console.log("Defining entry")
#entries = require '../controllers/entries'

Tag.

helper = require '../controllers/search_helper'

describe 'parsing pos', ->
  it 'should pos', ->
    obj = helper.parsePOS('.verb')
    expect(obj).toEqual( { 'senses.pos' : 'verb' } )

describe 'parsing Text', ->
  it 'should text', ->
    obj = helper.parseText('hello')
    expect(obj).toEqual( { 'senses.definitions.english' : /hello/i } )

describe 'parsing Text', ->
  it 'should text', ->
    obj = helper.parseText('안영')
    expect(obj).toEqual( { 'korean.hangul' : /안영/i } )

describe 'parsing Text', ->
  it 'should deal with hanja', ->
    obj = helper.parseText('韓')
    expect(obj).toEqual( { 'senses.hanja' : /韓/i } )

describe 'parsing tag', ->
  it 'problem tag', ->
    obj = helper.parseTag('!beans')
    expect(obj).toEqual( { 'beans.hanja' : /韓/i } )

describe 'parsing whole', ->
  it 'should detect types', ->
    obj = helper.parseQ('hello !there')
    expect(obj).toEqual( [ { 'senses.definitions.english' : /hello/i }, { 'tag.short' : 'there', 'tag.type' : 'problem' } ] )
    expect(1+2).toEqual 3

