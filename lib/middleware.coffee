
_ = require "underscore"

dbg = do ->
	_debug = false
	(msg) ->
		if _debug
			console.log msg

_defaultOptions = 
	errorHandler: (err) ->
		throw err

makeMiddlewareStack = (options) ->

	if options?
		_options = _.extend {}, _defaultOptions, options
	else
		_options = _.extend {}, _defaultOptions

	arityCheck = do ->
		if _options.enforceArity?
			(params...) ->
				_paramCount = _.size(params)
				unless _paramCount is _options.enforceArity
					err = new Error("Not enough parameters passed to middleware stack: arity enforcement set to #{_options.enforceArity}, but received #{_paramCount}.")
					_options.errorHandler(err)
		else
			->

	_middleware = []

	#default no-op middleware
	#uses a splat to handle multiple possible arities
	_defaultMiddle = (params...) ->
		nextFn = params[params.length - 1]
		nextFn()


	_middleware.push _defaultMiddle

	# push middleware onto the stack
	_useMiddleware = (midware) ->
		_middleware.push midware


	handleObjects = (objects, onEnd) ->
		arityCheck(objects)
		_nextMidware = do ->
			_index = 0
			_max = _middleware.length - 1
			_callNext = (freshObjects...) ->
				dbg("_callNext")
				_index++
				# push each call to the next middleware
				# onto the event loop (`process.nextTick`)
				# to avoid stack buildup.

				# if a value is passed on call to next, treat
				# that as the new response object.
				# 
				# The alternative is to just mutate the object
				# reference, which most people will do in practice.
				# That approach is more efficient, but then...
				# (hashtag #mutabilityProblems).
				# 
				# Because it's handled in this way, we can be
				# functional/OCD and make a clean object ref 
				# at each step.  If we want.

				toPass = 0
				if _.size(freshObjects) > 0
					dbg "fresh"
					toPass = freshObjects
				else
					dbg "clone"
					toPass = _.clone(objects)

				process.nextTick ->
					dbg("next midware")
					# here we invoke the next middleware,
					# if there is one.
					# if we've reached end of the middleware
					# stack, pass `req` on to the routing system.
					if _index <= _max
						dbg("getnext")
						toPass.push _callNext
						_middleware[_index].apply(null, toPass)
					else
						dbg("_passtoRoute")
						onEnd.apply(null, toPass)
						dbg("passed")
						return null
			_callNext


		# call the first registered middleware function, with ref
		# to `_nextMidware` to invoke next middleware.
		#
		# no need for bounds-checking because _middleware has
		# a default no-op handler as its first element

		dbg("midware")
		toPass = (_.clone(objects))
		toPass.push _nextMidware
		dbg("before")
		_middleware[0].apply(null, toPass)
		dbg("after")

	outs =
		use: _useMiddleware
		handle: handleObjects


module.exports = makeMiddlewareStack
