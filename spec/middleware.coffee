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

makeMidwareStack = require inlib("middleware.js")

describe "inmedia", ->
	describe "Midware", ->

		midware = makeMidwareStack()

		beforeEach ->
			midware = makeMidwareStack()

		it "has #handle and #use methods", ->
			assert( typeof midware.handle is "function" )
			assert( typeof midware.use is "function" )

		it "uses a passed middleware function to manipulate an object value", (done) ->
			fn = (obj, next) ->
				#console.log obj
				#console.log "aqui"
				obj.val *= 2
				#console.log obj
				next()
				#console.log "eh?"

			_routeObj =
				val: 5

			midware.use fn
			midware.handle [_routeObj], (routed...) ->
				obj = routed[0]
				assert (obj.val is 10)
				done()

		it "passes objects from one middleware function to the next", (done) ->



			fn = (obj, next) ->
				obj.val *= 2
				next()

			obj =
				val: 10

			midware.use fn
			midware.use fn

			midware.handle [obj], (handled...) ->
				assert( handled[0].val is 40)
				done()



		it "passed pipeline elements to middleware functions in the correct order", (done) ->

			fn1 = (obj, next) ->
				obj.val += 2
				next()

			fn2 = (obj, next) ->
				obj.val *= 2
				next()

			checkin = after 2, ->
				done()

			midware.use fn1
			midware.use fn2

			obj =
				val: 10

			midware.handle [obj], (handled...) ->
				assert( handled[0].val is 24 )
				checkin()

			midware = makeMidwareStack()

			midware.use fn2
			midware.use fn1
			obj =
				val: 10

			midware.handle [obj], (handled...) ->
				assert( handled[0].val is 22)
				checkin()

		it "allows for a flexible number of pipeline elements (handles different middleware function arities)", (done) ->


			obj1 =
				val: 10

			obj2 =
				val: 20

			obj3 =
				val: 30

			
			fn = (one, two, three, next) ->
				one.val += 1
				two.val += 2
				three.val += 3
				next()

			midware.use fn
			
			midware.handle [obj1, obj2, obj3], (handled...) ->
				assert( handled[0].val is 11 )
				assert( handled[1].val is 22 )
				assert( handled[2].val is 33 )
				done()

###

	it "enforces pipeline object count when the `enforceArity` option parameter is passed.", ->


		obj =
			val: 10
		
		fn = (one, next) ->
			one.val += 1
			next()


		errorHandler = (err) ->
			throw err


		midware = makeMidwareStack({enforceArity: 3, errorHandler: errorHandler})

		handler = (handled...) ->
			# do nothing
			# 
		toTest = ->
			midware.handle([obj], handler)

		midware.use fn
		assert.throws toTest, Error
###
