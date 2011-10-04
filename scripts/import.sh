/mongo/bin/mongoimport --dbpath data/ -d kdict -c entries --file kdict-entries.json --stopOnError
/mongo/bin/mongoimport --dbpath data/ -d kdict -c updates --file kdict-updates.json --stopOnError
/mongo/bin/mongoimport --dbpath data/ -d kdict -c tags --file kdict-tags.json --stopOnError

