// Generated by CoffeeScript 1.6.3
(function() {
  var dbg, makeMiddlewareStack, _, _defaultOptions,
    __slice = [].slice;

  _ = require("underscore");

  dbg = (function() {
    var _debug;
    _debug = false;
    return function(msg) {
      if (_debug) {
        return console.log(msg);
      }
    };
  })();

  _defaultOptions = {
    errorHandler: function(err) {
      throw err;
    }
  };

  makeMiddlewareStack = function(options) {
    var arityCheck, handleObjects, outs, _defaultMiddle, _middleware, _options, _useMiddleware;
    if (options != null) {
      _options = _.extend({}, _defaultOptions, options);
    } else {
      _options = _.extend({}, _defaultOptions);
    }
    arityCheck = (function() {
      if (_options.enforceArity != null) {
        return function() {
          var err, params, _paramCount;
          params = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          _paramCount = _.size(params);
          if (_paramCount !== _options.enforceArity) {
            err = new Error("Not enough parameters passed to middleware stack: arity enforcement set to " + _options.enforceArity + ", but received " + _paramCount + ".");
            return _options.errorHandler(err);
          }
        };
      } else {
        return function() {};
      }
    })();
    _middleware = [];
    _defaultMiddle = function() {
      var nextFn, params;
      params = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      nextFn = params[params.length - 1];
      return nextFn();
    };
    _middleware.push(_defaultMiddle);
    _useMiddleware = function(midware) {
      return _middleware.push(midware);
    };
    handleObjects = function(objects, onEnd) {
      var toPass, _nextMidware;
      arityCheck(objects);
      _nextMidware = (function() {
        var _callNext, _index, _max;
        _index = 0;
        _max = _middleware.length - 1;
        _callNext = function() {
          var freshObjects, toPass;
          freshObjects = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          dbg("_callNext");
          _index++;
          toPass = 0;
          if (_.size(freshObjects) > 0) {
            dbg("fresh");
            toPass = freshObjects;
          } else {
            dbg("clone");
            toPass = _.clone(objects);
          }
          return process.nextTick(function() {
            dbg("next midware");
            if (_index <= _max) {
              dbg("getnext");
              toPass.push(_callNext);
              return _middleware[_index].apply(null, toPass);
            } else {
              dbg("_passtoRoute");
              onEnd.apply(null, toPass);
              dbg("passed");
              return null;
            }
          });
        };
        return _callNext;
      })();
      dbg("midware");
      toPass = _.clone(objects);
      toPass.push(_nextMidware);
      dbg("before");
      _middleware[0].apply(null, toPass);
      return dbg("after");
    };
    return outs = {
      use: _useMiddleware,
      handle: handleObjects
    };
  };

  module.exports = makeMiddlewareStack;

}).call(this);
