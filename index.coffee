
_ = require "underscore"

dbg = do ->
	_debug = false
	(msg) ->
		if _debug
			console.log msg

path = require "path"

indirFact = (aDir) ->
	if aDir?
		_dir = path.join __dirname, aDir
	else
		_dir = __dirname
	(fName) ->
		path.join _dir, fName

indir = indirFact()

inlib = indirFact("lib")

makeMidwareStack = require inlib("middleware.js")
makePredRouter = require inlib("predroute.js")

_defaultOptions =
	defaultRoute: (req) -> 
		throw new Error("No default route provided.")



makeMiddlewareRouter = (options) ->
	if options?
		_options = _.extend({}, _defaultOptions, options)
	else
		_options = _.clone(_defaultOptions)



	_middleware = makeMidwareStack()
	_router = makePredRouter()


	#push middleware onto the stack
	#middleware is a function with ()
	_useMiddleware = (midware) ->
		dbg("useMiddleware")
		_middleware.use midware

	_useRoute = (pred, handler) ->
		dbg("useRoute")
		_router.use(pred, handler)



	# call _pickRoute to determine correct handler.
	# pass `req` to handler on `process.nextTick`
	_passToRouter = (reqs...) ->
		process.nextTick ->
			_router.handle reqs


	# passed an array of pipeline objects by output#handle()
	_handleRequest = (reqs...) ->

		dbg("handleRequest")
		_middleware.handle reqs, _passToRouter
	
	outputRef = {}

	###*
	 * Add a middleware function to the stack.  Middleware is a function with a `req, res, next`-type signature, as in Connect, but the number of parameters before `next` is allowed to vary for the sake of flexibility.  In practice this should be locked down with the global `enforceArity` option.
	 *
	 * @param {Function} midwareFn A middleware function which will receive pipeline element(s) and a `next` method to call if the objects should continue down the route.
	 * @return {Router} The same router instance is returned (chained).
	###	
	outputRef.useMiddleware = _useMiddleware

	###*
	 * Pass object(s) in for handling as pipeline elements.  Objects wil be filtered through middleware and then routed.  In Connect, this corresponds to the client's HTTP request being passed to Connect's middleware handling system. 
	 * 
	 * @param {Object(s)} elem1[,elem2...] One or more objects to be passed through the middleware and routing systems.  In Connect, these would be the `req` and `res` objects.
	 * @return {Router} The same router instance is returned (chained).
	###	
	outputRef.handle = _handleRequest


	###*
	 * Define a route by passing in a predicate (truth-test) and route handler.
	 * 
	 * A route is specified by passing in two functions.  The first is a predicate which is passed the piped object(s), inspects them, and returns `true` if it wants to accept responsibility for them. Otherwise, it should return `false` or should not return at all.  This predicate is a generalization of Connect's URL-based routing, intended for pipelines where there may not be an obvious single string to base routing on. 
	 *
	 * If the predicate returns true, the object(s) are removed from the pipeline and passed to the the route handler.  No route predicates further down the pipeline are tested: the earlier a route is defined in the script, the higher its priority.
	 * 
	 * The route handler should implement the actual logic / data operations associated with the route: extracting information, writing results to disk, and so on.  Implementing this kind of code in the predicate may make the pipeline difficult to modify.
	 *
	 * @param {Function} predicateFn A function which is passed the routed object(s) and returns `true` if its associated handler should be passed the objects.
	 * @param {Function} handlerFn A function which is passed the routed object(s) if its associated predicate returns true, after which the objects are removed from the pipeline and no further route predicates are tested.
	 * @return {Router} The same router instance is returned (chained).
	###	
	outputRef.useRoute = _useRoute
	

	###*
	 * Get the value of a router-wide option, if it's defined.
	 * @param {String} optName The parameter name.
	 * 
	 * @return {Any,null} Return type depends on the particular setting, and most settings will be defined by code layered on top of the router.  `null` is returned if the option has not been defined.
	###	
	outputRef.get = (aKey) ->
		if _options[aKey]?
			_options[aKey]
		else
			null

	###*
	 * Set the value of a router-wide option, given as a key-val pair, or set the value of multiple options by passing in an object.
	 * @param {String,Object} optName The name of the option to be set, if given as a key-value pair.  Alternately, an object with multiple options to be set.
	 * @param {Any} newVal The updated value of the option, if given as a key-value pair.
	 * 
	 * @return {Router} The same router instance is returned (chained).
	###	
	outputRef.set = (aKey, aVal) ->
		if _.isObject(aKey)
			# hash of key-val pairs passed in
			_.extend _options, aKey
		else
			_options[aKey] = aVal
		return outputRef

	return outputRef

exp = {}


###*
 * A factory function for constructing new routers.  It isn't a constructor function, so there's no need to call it with `new`.
 * 
 * Options include: 
 * 
 * -	`defaultRoute`: a route to use if no route predicate returns true.  The built-in `defaultRoute` throws an error.
 * -	`enforceArity`: limits middleware and routing handlers to the given arity, _plus one_ for the `next` parameter.
 * 
 * 
 * There is no default arity enforcement.  Internally, `next` is appended onto the array of passed parameters and they're all passed to a handler via `#apply`.
 *
 * @param {Object} options A hash of options 
 * 
 * @return {Object} A new routing object with methods for adding middleware, adding routes, handling new pipeline elements, and getting and setting options. 
###
exp.inmedia = makeMiddlewareRouter



module.exports = exp.inmedia
