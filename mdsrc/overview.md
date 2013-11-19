__inmedia__ allows for routes based on any number of pipeline elements, so Connect's `(req, res, next)` signature can be replaced by `(justOne, next)` or `(oneFish, twoFish, redFish, blueFish, next)`.  This flexibility can be locked down with optional arity enforcement, specified with an `enforceArity` property on the options object passed in at construction.

```javascript
var inmedia = require("inmedia");
var _ = require("underscore");

var midware = function(one, two, three, four, next) {
	one.val += 1;
	two.val += 2;
	three.val += 3;
	four.val += 4;
	next();
}
var router = inmedia();
router.useMiddleware(midware);
var always = function() { return true; }


router.useRoute(always, function(one, two, three, four) {
	var current = 1;
	_.each( [one, two, three, four], function(oneVal) {
		console.log(current + ": " + oneVal.val);
		current++;
	});
})
router.handle({val: 10}, {val: 20}, {val: 30}, {val: 40});

// output: 
// 1: 11
// 2: 22
// 3: 33
// 4: 44
```

####Routing
Routing is based on predicate functions instead of strings, enabling a much wider variety of use cases:

```javascript
var inmedia = require "inmedia";
var router = inmedia();

var isEven = function(num) {
	if (num % 2) return false;
	return true;
}
var isOdd = function(num) {
	if (num % 2) return true;
	return false;
}
var oddRoute = function(dataObj) {
	console.log("ODD: " + dataObj.val);
}
var evenRoute = function(dataObj) {
	console.log("EVEN: " + dataObj.val);
}

router.useRoute(isEven, evenRoute);
router.useRoute(isOdd, oddRoute);
router.handle({val: 9});
router.handle({val: 15});
router.handle({val: 10});

// output:
// ODD: 9
// ODD: 15
// EVEN: 10

```

It's simple to implement string-based routing on top of the predicate system.  A basic version for URI-based routing: 

```javascript
var uriStringToPred = function(uri) {
	return function(page) {
		if (page.uri === uri) return true;
		return false;
	}
}
router.useRoute(uriStringToPred("/some/route"), routeHandler);
```

####Simple Examples

__inmedia__ can be used as a pipeline for event handling, or for any process involving data filtration and/or manipulation.

#####Filtering with Middleware:

```javascript
var onlySmiths = function(person, next) {
	if (person.lastName === "Smith") {
		next();
	}
	// else do nothing, and
	// element falls out of pipeline
}

var printPerson = function(person) {
	console.log("first: " + person.first 
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

#####Sorting with Routes:

```javascript

var is18OrOver = function(person) {
	if (person.age >= 18) return true;
	return false;
}
var isUnder18 = function(person) {
	if (person.age < 18) return true;
	return false
} 

var router = inmedia();
var childRoute = function(person) {
	console.log("CHILD: " + person.name);
}
var adultRoute = function(person) {
	console.log("ADULT: " + person.name);
}
router.use(is18OrOver, adultRoute);
router.use(isUnder18, childRoute);

router.handle({name: "Billy Bob", age: 47});
router.handle({name: "Mary-Beth Anne Peters Washington", age: 28});
router.handle({name: "Little Jimmy", age: 8});

// output:
// "ADULT: Billy Bob"
// "ADULT: Mary-Beth Anne Peters Washington"
// "CHILD: Little Jimmy"
```

#####Data Manipulation or Augmentation:

```javascript
var request = require("request");
var inmedia = require("inmedia");

var dogMiddleware = function(dog, next) {
	dog.ageInHumanYears = dog.age * 7;
	next()
}

var router = inmedia();
router.useMiddleware(dogMiddleware);

var always = function() { return true; }
router.useRoute(always, function(dog) {
	var message = dog.name + " is " + dog.ageInHumanYears + " in human years.";
	console.log(message);
});

router.handle({name: "Old Yeller", age: 12});

//output :
// "Old Yeller is 84 in human years."
```

[See the API for more ==>][api]


[api]: ./api.html

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
