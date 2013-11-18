assert = require "better-assert"

path = require "path"

inlib = do ->
	_libdir = path.join __dirname, "../lib"
	(fName) ->
		path.join _libdir, fName


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


makePredRouter = require inlib("predroute.js")

describe "PredRouter", ->

	router = makePredRouter()

	beforeEach ->
		router = makePredRouter()

	it "has #handle and #use methods", ->
		assert( typeof router.handle is "function" )
		assert( typeof router.use is "function" )


	it "accepts and uses a predicate-handler pair", (done) ->
		obj =
			val: 10

		handler = (obj) ->
			assert (obj.val is 10)
			done()

		router.use always, handler

		router.handle [obj]

	it "chooses the route based on predicate result, not on sequence alone", (done) ->

		obj =
			val: 10

		handler = (obj) ->
			assert (obj.val is 10)
			done()

		badHandler = ->

		router.use never, badHandler
		router.use always, handler

		router.handle [obj]

	it "allows for a flexible number of pipeline objects", (done) ->

		obj1 =
			val: 10

		obj2 =
			val: 20

		obj3 =
			val: 30

		obj4 =
			val: 40

		handler = (one, two, three, four) ->
			assert( one.val is 10)
			assert( two.val is 20)
			assert( three.val is 30)
			assert( four.val is 40)
			done()

		badHandler = ->

		router.use always, handler

		router.handle [obj1, obj2, obj3, obj4]

	it "chooses the first true route when multiple predicates would return true for the objects", (done) ->

		goodHandle = (obj) ->
			done()

		badHandle = ->

		obj =
			val: 10

		router.use always, goodHandle
		router.use always, badHandle

		router.handle [obj]
