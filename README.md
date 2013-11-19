
Node.js: inmedia
=================
Scott Ivey -> http://www.scivey.net

__inmedia__ is an abstracted [Connect][connecturl]-like middleware and routing component for Node.js, with flexible handler signatures and predicate-based routing.

[connecturl]: http://www.senchalabs.org/connect/

It enables the aggregation of simple, reusable handler functions into complex filtering and data transformations.  

The following __inmedia__-based pipeline downloads a given webpage and searches it for the word "Todd."  If "Todd" appears anywhere on the page, it extracts every link, downloads those pages, and repeats the cycle until two hundred pages have been fetched or the trail runs cold.  Each result is written to disk as "toddResults/result_NUM.json".

Why Todd?  Because we like Todd, or maybe because we hate him.

It is unlikely that we are Todd-neutral.


```javascript
var request = require("request");
var inmedia = require("inmedia");

var router = inmedia();
var makeRequest = function(page) {
	request(page.uri, function(err, response, body)) {
		page.body = body;
		router.handle(page);
	}
}

var pageCount = 0;
var limiter = function(page, next) {
	pageCount++;
	if (pageCount < 200) next();
}
router.useMiddleware(limiter);

var toddFilter = function(page, next) {
	var toddRegex = /\bTodd\b/m;
	if (toddRegex.test(page.body)) next();
}
router.useMiddleware(toddFilter);

var linkExtractionRoute = function(page) {
	var linkRegex = /\bhref="([^"]+)"\b/igm
	var match;
	while( match = linkRegex.exec(page.body) ) {
		makeRequest({uri: match[1]});
	}
	var outputFile = "toddResults/result_" + pageCount + ".json";
	fs.writeFile(outputFile, JSON.stringify(page), function(err) {
		console.log("Wrote to " + outputFile);
	});
}
router.useRoute(linkExtractionRoute);
router.handle({uri: "http://www.google.com/search?q=todd});
```

Overview
---

__inmedia__ allows for routes based on any number of pipeline elements, so Connect's `(req, res, next)` signature can be replaced by `(justOne, next)` or `(oneFish, twoFish, redFish, blueFish, next)`.  This flexibility can be locked down with optional arity (argument-count) enforcement, specified with an options hash passed in at construction.

Routing is based on predicate functions instead of strings, enabling a much wider variety of use cases.

```javascript
var inmedia = require "inmedia";
var router = inmedia();

var midware = function(pipelineElem, next) {
	pipelineElem.val += 5;
	next()
}

var always = function() {return true;}
var logRoute = function(pipelineElem) {
	console.log("Received value: " + pipelineElem.val);
}

router.useMiddleware(midware);
router.useRoute(always, logRoute);
router.handle( {val: 20} );

// output:
// "Received value: 25"

```

Overview
------

__inmedia__ can be used as a pipeline for event handling, or for any process involving data filtering, manipulation and/or sorting.

Filtering:

```javascript
var onlySmiths = function(person, next) {
	if (person.lastName === "Smith") {
		next();
	}
	// else do nothing, and
	// element falls out of pipeline
}

var printPerson = function(person) {
	console.log("\nfirst: " + person.first 
				+ "  last: " + person.last );
}

var router = inmedia();
router.useMiddleware(onlySmiths);
router.useRoute(always, printPerson);
router.handle({firstName: "John", lastName: "Smith"});
router.handle({firstName: "Colonel", lastName: "Mustard"})
router.handle({firstName: "Nikola", lastName: "Tesla"});
router.handle({firstName: "Mary", lastName: "Smith"});


// output:
// "first: John  last: Smith"
// "first: Mary  last: Smith"

```

Sorting:

```javascript

var isOdd = function(valObject) {
	if (valObject.value % 2) {
		return true;
	}
	return false;
}

var isEven = function(valObject) {
	if (valObject.value % 2) {
		return false;
	}
	return true;
}

var oddHandler = function(valObj) {
	console.log("Got ODD: " + valObj.val);
}
var evenHandler = function(valObj) {
	console.log("Got EVEN: " + valObj.val);
}

var router = inmedia();

router.useRoute(isOdd, oddHandler);
router.useRoute(isEven, evenHandler);
router.handle({val: 3});
router.handle({val: 17});
router.handle({val: 8});

// Output:
// "Got ODD: 3"
// "Got ODD: 17"
// "got EVEN: 8"
```

Manipulation or augmentation:

```
// make an HTTP request for each URI
// passing through the pipeline.
// wait for the response, then append response body
// to the data element before passing it down the pipe.

var request = require("request");
var inmedia = require("inmedia");

var uriFetcher = (pageObj, next) {
	var uri = pageObj.uri;
	request(uri, function(err, response, body) {
		uri.body = body;
		next();
}
var router = inmedia();
router.useMiddleware(uriFetcher);


router.useHandler(always, function(pageObj) {
	console.log(pageObj.toddIndices)
});
router.handle({uri: "http://www.cnn.com"});
```


Why Todd?  Because we like Todd, or maybe because we hate him.

It is unlikely that we are Todd-neutral.

```javascript
var request = require("request");
var inmedia = require("inmedia");

var uriFetcher = (pageObj, next) {
	var uri = pageObj.uri;
	request(uri, function(err, response, body) {
		uri.body = body;
		next();
}

var toddParser = (pageObj, next) {
	// get the string index of every appearance of
	// the word "Todd" in the page body.
	var toddRegex = /\bTodd\b/gm;
	var toddIndices = [];
	var match;
	while ( match = toddRegex.exec(pageObj.body) ) {
		toddIndices.push( match.index );
	}
	pageObj.toddIndices = toddIndices;
	next();
}

var toddFilter = (pageObj, next) {
	if (pageObj.toddIndices.length > 0) {
		next()
	}
}

var router = inmedia();
router.useMiddleware(uriFetcher);
router.useMiddleware(toddParser);
router.useMiddleware(toddFilter);

router.useHandler(always, function(pageObj) {
	console.log( "Found todd at: " + pageObj.uri);
	// write the results to file or database
});

router.handle({uri: "http://www.cnn.com"});
router.handle({uri: "http://www.foxnews.com"});
// find Todd on the only news sites worth reading

```

Using a pipeline-based approach means that all of the logic needed to combine the various handlers is already in place.  This means that handlers tend to stay modular and loosely coupled.  For instance, the `toddParser` function defined above could be reused for Todd-related information extraction from any text string.  The `toddFilter` handler could be reused for any operation related to Todd filtration.  There are many.

[See the API ==>][api]


Installation
------------

    npm install inmedia


GitHub
------------
https://github.com/scivey/inmedia


Contact
------------
https://github.com/scivey

http://www.scivey.net

scott.ivey@gmail.com

License
------------
MIT License (MIT)

Copyright (c) 2013 Scott Ivey, <scott.ivey@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
