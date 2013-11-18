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

describe "predRouter: functional", ->

	router = makePredRouter()

	beforeEach ->
		router = makePredRouter()

	badHandle = ->

	# less than 10
	predLT10 = (obj) ->
		if obj.val < 10
			true
		else
			false

	# even
	predEven = (obj) ->
		if obj.val % 2
			false
		else
			true

	# greater than 30
	predGT30 = (obj) ->
		if obj.val > 30
			true
		else
			false

	# odd
	predOdd = (obj) ->
		if obj.val % 2
			true
		else
			false

	it "chooses the first correct route - part 1", (done) ->
		obj =
			val: 8

		goodHandle = ->
			done()

		router.use predGT30, badHandle
		router.use predOdd, badHandle
		router.use predLT10, goodHandle
		router.use predEven, badHandle

		router.handle [obj]

	it "chooses the first correct route - part 2", (done) ->

		obj =
			val: 37

		goodHandle = ->
			done()

		router.use predGT30, goodHandle
		router.use predOdd, badHandle
		router.use predLT10, badHandle
		router.use predEven, badHandle

		router.handle [obj]

	it "chooses the first correct route - part 3", (done) ->

		obj =
			val: 7

		goodHandle = ->
			done()

		router.use predGT30, badHandle
		router.use predOdd, goodHandle
		router.use predLT10, badHandle
		router.use predEven, badHandle

		router.handle [obj]

	it "chooses the first correct route - part 4", (done) ->

		obj =
			val: 32

		goodHandle = ->
			done()


		router.use predOdd, badHandle
		router.use predLT10, badHandle
		router.use predEven, goodHandle
		router.use predGT30, badHandle

		router.handle [obj]

