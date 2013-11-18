
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


### *
*	Instantiate a new router.
*	@param {Object} options A hash of options 
*
* 	Options include:
* 		- defaultRoute: a route to use if no route predicate returns true.
* 		- enforceArity: if present, limits middleware and routing handlers to the given arity PLUS ONE for the `next()` parameter.
* 			By default, there is no arity enforced.  Internally, `next` is appended onto the passed parameters and they're passed to the handlers with `#apply(null, params)`.
*
*
*	@return {Object} A new routing object with methods adding middleware, adding routes, handling new pipeline objects, and getting and setting options. 
###
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
	_handleRequest = (reqs) ->

		dbg("handleRequest")
		_middleware.handle reqs, _passToRouter
	
	outputRef = {}

	###*
	 * Add a middleware function to the stack.  Middleware is a function with a `req, res, next`-type signature, as in Connect, although the number of parameters before `next` is allowed to vary for the sake of flexibility.  In practice this should be locked down with the global `enforceArity` option.
	 *
	 * @param {Function} A middleware function which will receive route object(s) and a `next` method to call if the objects should continue down the route.
	 * @return {Router} The same router instance is returned (chained).
	###	
	outputRef.useMiddleware = _useMiddleware

	###*
	 * Pass object(s) in for handling.  Objects wil be filtered through middleware and then routed.  In Connect, this would correspond to the client's HTTP request being passed to Connect's middleware handling system. 
	 * 
	 * @param {Object} One or more objects to be passed through the middleware and routing systems.  In Connect, this would be the `req` and `res` objects.
	 * @return {Router} The same router instance is returned (chained).
	###	
	outputRef.handle = _handleRequest


	###*
	 * Define a route (pipeline endpoint).  An endpoint is specified by passing in two functions.  The first is a predicate which is passed the piped object(s), inspects them, and returns `true` if it wants to accept responsibility for them. Otherwise, it should return `false` or should not return at all.  This predicate is a generalization of Connect's URL-based routing, intended for pipelines where there may not be an obvious single string to base routing on. 
	 *
	 * The second function is a handler.  If the predicate returns true, the object(s) are removed from the pipeline and passed to this handler.  No route predicates further down the pipeline are tested: the earlier a route is defined in the script, the higher its priority.
	 * 
	 * @param {Function} predicate A function which is passed the routed object(s) and should return `true` if its associated handler should be passed the objects.
	 * @param {Function} handler A function which is passed the routed object(s) if its associated predicate returns true, after which the objects are removed from the pipeline and no further route predicates are tested.
	 * @return {Router} The same router instance is returned (chained).
	###	
	outputRef.useRoute = _useRoute
	

	###*
	 * Get the value of a router-wide option, if it's defined.
	 * @param {String} optName The parameter name.
	 * 
	 * @return {Any} Return type depends on the particular setting, and most settings will be defined by code layered on top of the router.
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

module.exports = makeMiddlewareRouter
