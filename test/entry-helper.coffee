

exports.single = (hangul, english, hanja, callback) ->
  ->
    if not Array.isArray(english)
      english = [ english ]
    entry = new Entry
      korean:
        hangul: hangul
      senses: [
        definitions:
          english: english
      ]
    if hanja
      if not Array.isArray(hanja)
        hanja = [ hanja ]
      entry.senses[0].hanja = hanja
    entry.save callback
