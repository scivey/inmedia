assert = require "better-assert"

path = require "path"

inlib = do ->
	_libdir = path.join __dirname, "../lib"
	(fName) ->
		path.join _libdir, fName

inBase = do ->
	_basedir = path.join __dirname, "../"
	(fName) ->
		path.join _basedir, fName


after = (total, callback) ->
	_soFar = 0
	_called = false
	callMeMaybe = ->
		_soFar++
		if _soFar >= total and _called is false
			callback()
			_called = true


always = -> true
never = -> false

makeMidwareRouter = require inBase("index.js")

doneHandler = (doneFn, assertion) ->
	(results...) ->
		if assertion?
			assertion.apply null, results
		doneFn()


describe "MidwareRouter", ->

	pipeline = makeMidwareRouter()

	beforeEach ->
		pipeline = makeMidwareRouter()

	it "uses the middleware it's passed", (done) ->

		midware = (obj, next) ->
			obj.val *= 2
			next()

		handler = (obj) ->
			assert( obj.val is 20)
			done()

		anObj =
			val: 10

		pipeline.useMiddleware midware
		pipeline.useRoute always, handler
		pipeline.handle [anObj]

	it "uses passed middleware in the correct order.", (done) ->

		midware1 = (obj, next) ->
			obj.val += 5
			next()

		midware2 = (obj, next) ->
			obj.val *= 2
			next()

		midware3 = (obj, next) ->
			obj.val -= 3
			next()


		anObj =
			val: 10

		# 10 + 5 = 15
		# 15 * 2 = 30
		# 30 - 3 = 27

		handler = (obj) ->
			assert (obj.val is 27)
			done()

		pipeline.useMiddleware midware1
		pipeline.useMiddleware midware2
		pipeline.useMiddleware midware3

		pipeline.useRoute always, handler
		pipeline.handle [anObj]

	it "uses the first true-returning route.", (done) ->

		midware = (obj, next) ->
			next()

		anObj =
			val: 10

		# 10 + 5 = 15
		# 15 * 2 = 30
		# 30 - 3 = 27

		goodHandler = (obj) ->
			done()

		badHandler = ->

		pipeline.useMiddleware midware
		pipeline.useRoute always, goodHandler
		pipeline.useRoute always, badHandler

		pipeline.handle [anObj]

	it "chooses the correct route based on predicate return value, not on route sequence alone.", (done) ->

		midware = (obj, next) ->
			next()

		anObj =
			val: 10

		goodHandler = (obj) ->
			done()

		badHandler = ->

		pipeline.useMiddleware midware
		pipeline.useRoute never, badHandler
		pipeline.useRoute always, goodHandler

		pipeline.handle [anObj]

	it "allows for a flexible number of pipeline objects", (done) ->

		obj1 =
			val: 10

		obj2 =
			val: 20

		obj3 =
			val: 30

		midware = (one, two, three, next) ->
			one.val += 1
			two.val += 2
			three.val += 3
			next()

		handler = (one, two, three) ->
			assert( one.val is 11 )
			assert( two.val is 22 )
			assert( three.val is 33 )
			done()

		pipeline.useMiddleware midware
		pipeline.useRoute always, handler

		pipeline.handle [obj1, obj2, obj3]

