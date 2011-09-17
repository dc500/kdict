

// some test data

var entry = new Entry( {
    korean : {
                 hangul : '안녕하세요',
             }
} );

entry.save();

entry.korean.length.should.equal(5);

