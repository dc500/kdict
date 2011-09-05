# KDict - Open-source Korean Dictionary

KDict is an open-source Korean dictionary that anyone can edit and contribute to.
It aims to be a long-term data source for developers and researchers to use freely in Korean-language projects.

This repository contains the [kdict.org](http://kdict.org) site code, as well as language processing scripts used to maintain the data.

Visit [kdict.org](http://kdict.org) to use the dictionary, download the raw data or contribute to the project.


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
	pronunciation: '음식', // fill programmatically
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