
__inmedia__ is an abstracted [Connect][connecturl]-like middleware and routing system for Node.js, with flexible handler signatures and predicate-based route selection.

[connecturl]: http://www.senchalabs.org/connect/

It enables the aggregation of simple, reusable handler functions into complex filters and data transformations.  

The following __inmedia__-based pipeline downloads a given webpage and searches it for the string _Todd_.  If _Todd_ appears anywhere on the page, it extracts every link, downloads those pages, and repeats the cycle until two hundred pages have been fetched or the trail runs cold.  Each result is written to disk for later processing.

Why Todd?  Because we like Todd, or maybe because we hate him.  Either way, it's clear we have strong feelings.

```javascript
var request = require("request");
var inmedia = require("inmedia");

var router = inmedia();
var makeRequest = function(page) {
	request(page.uri, function(err, response, body)) {
		console.log("Fetched URI: " + page.uri);
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
	var linkRegex = /\bhref="([^"]+)"\b/igm;
	var match;
	while( match = linkRegex.exec(page.body) ) {
		makeRequest({uri: match[1]});
	}
	var outputFile = "toddResults/result_" + pageCount + ".json";
	fs.writeFile(outputFile, JSON.stringify(page), function(err) {
		console.log("Wrote to " + outputFile);
	});
}
var always = function() { return true; }
router.useRoute(always, linkExtractionRoute);
router.handle({uri: "http://www.google.com/search?q=todd"});
```

By relying on __inmedia__'s lightweight architecture for routing logic and flow control, all of the utility functions defined above remain modular and don't become tightly coupled to this particular pipeline.  The `toddParser` function is general enough to be reused for Todd-related information extraction from any text string.  The `toddFilter` handler can be reused for any operation related to Todd filtration.  There are many.

[Read the overview][overview], then see the [API][api] and [test suite][tests].

[api]:./api.html
[tests]:./spec.html
[overview]:./overview.html