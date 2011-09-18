# KDict - Open-source Korean Dictionary

KDict is an open-source Korean dictionary that anyone can edit and contribute to.
It aims to be a long-term data source for developers and researchers to use freely in Korean-language projects.

This repository contains the [kdict.org](http://kdict.org) site code, as well as language processing scripts used to maintain the data.

Visit [kdict.org](http://kdict.org) to use the dictionary, download the raw data or contribute to the project.


## Installation

Here's how to get a local copy of KDict running for development purposes:

1. Download the source
```
$ git clone git://github.com/bhumphreys/kdict.git
```
2. Install [NPM](http://npmjs.org/)
3. Install the required packages
4. Install [MongoDB](http://www.mongodb.org/)
5. Download the [latest data dump](http://kdict.org/developers/download) and import using ```[mongoimport](http://www.mongodb.org/display/DOCS/Import+Export+Tools#ImportExportTools-mongoimport)```
6. Start an instance of the MongoDB server ```mongod```
7. Start KDict server with ```coffee app.coffee```


## Data

The core of KDict is the dictionary data. The project's main goal is to provide high-quality data that can be used in any Korean-language project.

KDict uses MongoDB for its storage, and so each dictionary entry is a hierarchical document.
The format of this is still being revised, but the current draft is shown below:

```yaml
entry: {
	korean: {
		word: '음식',
		length: 2, // for ordering search results
	},
	pronunciation: { // fill programmatically
		hangul: '음식',
		rr:     'eum.sik',
		yale:   'um.sik',
		mr:     'ŭm.sik',
		ipa:    'ɨm.ʃik]'
	},
	hanja: '飮食', 
	difficulty: 4,
	frequency: 24,
	definitions: {
		english: [
			'food',
			'meal'
		],
		japanese: [
			'飲食',
			'食べ物'
		],
	},
	pos: 2, // part-of-speech tag. E.g. verb, noun etc.
	requested: { // Times requested via tools
		web: 2,
		api: 0,
		plugin: 42
	},
	examples: [
		// Connect to tatoeba.org
	],
	submitter: 'username2352',
	source: 'something', // engdic, website url, book name, user entry ]
	created_at: date,
	updated_at: date
}
```