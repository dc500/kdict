assert   = require "assert"

exports.assertPropErr = (prop) ->
  (err, thingy) ->
    assert.isUndefined thingy
    assert.isNotNull   err
    assert.isNotNull   err.errors[prop]

