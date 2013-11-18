
_ = require "underscore"

dbg = do ->
	_debug = false
	(msg) ->
		if _debug
			console.log msg

_defaultOptions = 
	errorHandler: (err) ->
		throw err
	defaultRoute: (req) -> 
		throw new Error("No default route provided.")

makePredRouter = (options) ->

	if options?
		_options = _.extend {}, _defaultOptions, options
	else
		_options = _.extend {}, _defaultOptions

	arityCheck = do ->
		if _options.enforceArity?
			(params...) ->
				_paramCount = _.size(params)
				unless _paramCount is _options.enforceArity
					err = new Error("Not enough parameters passed to router stack: arity enforcement set to #{_options.enforceArity}, but received #{_paramCount}.")
					_options.errorHandler(err)
		else
			->

	_routes = []


	# push route handling object onto the stack,
	# which is an object with `predicate` and 
	# `handler` properties
	_useRouteObj = (route) ->
		_routes.push route

	# `useRoute` converts separate (predicate, handler)
	# into object with those properties
	_useRoute = (routePredicate, routeHandler) ->
		dbg(routePredicate)
		dbg(routeHandler)
		_route =
			predicate: routePredicate
			handler: routeHandler
		_useRouteObj(_route)

	# run req/res objects through the route predicates.
	# return the first route with true-returning predicate.
	# passed an array of pipeline objects
	_pickRoute = (reqs) ->
		dbg("pickRoute")
		_chosenHandler = false

		if _routes.length > 0
			routeCount = _routes.length - 1
			_it = 0
			# pass objects to route predicates in first->last
			# sequence.  Give it to the first handler
			# to return true.
			while _it < _routes.length
				predResult = _routes[_it].predicate.apply(null, reqs)
				if predResult
					_chosenHandler = _routes[_it]
					break
				_it++

		# if predicate loop didn't return a handler,
		# see if we have a default handler registered.
		unless _chosenHandler
			if _options.defaultRoute?
				dbg("defaultRoute")
				_chosenHandler = 
					handler: _options.defaultRoute

		return _chosenHandler



	# call _pickRoute to determine correct handler.
	# pass `req` to handler on `process.nextTick`
	_handleRouting = (reqs) ->
		_routeHandler = _pickRoute(reqs)
		process.nextTick ->
			_routeHandler.handler.apply(null, reqs)

	output =
		handle: _handleRouting
		use: _useRoute


module.exports = makePredRouter
