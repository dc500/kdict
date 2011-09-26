# KDict - Open-source Korean Dictionary

KDict is an open-source Korean dictionary that anyone can edit and contribute to.
It aims to be a long-term data source for developers and researchers to use freely in Korean-language projects.

This repository contains the [kdict.org](http://kdict.org) site code, as well as language processing scripts used to maintain the data.

Visit [kdict.org](http://kdict.org) to use the dictionary, download the raw data or contribute to the project.


## Installation

Here's how to get a local copy of KDict running for development purposes:

1. Download the source with ```$ git clone git://github.com/bhumphreys/kdict.git```
2. Install [NPM](http://npmjs.org/)
3. Install the required packages
4. Install [MongoDB](http://www.mongodb.org/)
5. Download the [latest data dump](http://kdict.org/developers/download) and import into a db/collection called ``kdict``/``entries`` using [```mongoimport```](http://www.mongodb.org/display/DOCS/Import+Export+Tools#ImportExportTools-mongoimport)
6. Start an instance of the MongoDB server ```mongod```
7. Start KDict server with ```coffee app.coffee```
8. View the site at http://localhost:3000


## Data

The core of KDict is the dictionary data. The project's main goal is to provide high-quality data that can be used in any Korean-language project.

Nightly dumps are available at [KDict's developer download page](http://kdict.org/developers/download)

KDict uses MongoDB for its storage, and so each dictionary entry is a hierarchical document.
The format of this is still being revised, but the current draft is shown below:


#### Format

```yaml
entry: {
	korean: {
		hangul: '음식',
		length: 2,
		
		// Filled programmatically, TODO
		rr:     'eum.sik',
		yale:   'um.sik',
		mr:     'ŭm.sik',
		ipa:    'ɨm.ʃik]'
	},
	// A single surface-form can have multiple word senses
	senses: [
		hanja: [ '飮食' ],
		definitions: {
			english: [
				'food',
				'meal'
			],
		},
		pos: 2, // part-of-speech tag. E.g. verb, noun etc.
	]
}
```