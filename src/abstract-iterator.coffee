# Copyright (c) 2013 Rod Vagg, MIT License
# Copyright (c) 2014 Riceball LEE, MIT License
xtend                 = require("xtend")
minimatch             = require('minimatch')
Errors                = require('abstract-error')
consts                = require('./consts')
inherits              = require("inherits-ex")
isArray               = require("util-ex/lib/is/type/array")
isString              = require("util-ex/lib/is/type/string")
isFunction            = require("util-ex/lib/is/type/function")
isBuffer              = require("util-ex/lib/is/type/buffer")

AbstractError         = Errors.AbstractError
NotImplementedError   = Errors.NotImplementedError
NotFoundError         = Errors.NotFoundError
InvalidArgumentError  = Errors.InvalidArgumentError
createError           = Errors.createError
AlreadyEndError       = createError("AlreadyEnd", 0x53)
AlreadyRunError       = createError("AlreadyRun", 0x54)

FILTER_INCLUDED = consts.FILTER_INCLUDED
FILTER_EXCLUDED = consts.FILTER_EXCLUDED
FILTER_STOPPED  = consts.FILTER_STOPPED

Errors.AlreadyEndError  = AlreadyEndError
Errors.AlreadyRunError  = AlreadyRunError


module.exports = class AbstractIterator
  @AlreadyEndError: AlreadyEndError
  @AlreadyRunError: AlreadyRunError

  constructor: (@db, options) ->
    @_ended = false
    @_nexting = false
    @options = @initOptions(options)
    options = @options

    isKeysIterator = options and isArray options.range
    if isKeysIterator
      @_resultOfKeys = options.range
      @_indexOfKeys = -1

    return not isKeysIterator

  initOptions: (options)->
    options = xtend(options)
    options.reverse = !!options.reverse

    range = options.range
    if isString(range)
      range = range.trim()
      if range.length >= 2
        skipStart = if !options.reverse then range[0] is "(" else range[range.length-1] is ")"
        skipEnd   = if !options.reverse then range[range.length-1] is ")" else range[0] is "("
        range     = range.substring(1, range.length-1)
        range     = range.split(",").map (item)->
          item = item.trim()
          item = null if item is ""
          return item
        if !options.reverse
          [start,end] = range
          startOp = 'gt'
          endOp = 'lt'
        else
          [end, start] = range
          startOp = 'lt'
          endOp = 'gt'
        startOp = startOp + 'e' unless skipStart
        endOp = endOp + 'e' unless skipEnd
        options[startOp] = start
        options[endOp] = end
    options.keys = options.keys isnt false
    options.values = options.values isnt false
    options.limit = (if "limit" of options then options.limit else -1)
    options.keyAsBuffer = options.keyAsBuffer is true
    options.valueAsBuffer = options.valueAsBuffer is true
    if options.next
        if options.reverse isnt true
          options.gt = options.next
          options.gte= options.next
        else
          options.lt = options.next
          options.lte= options.next
    ["start", "end", "gt", "gte", "lt", "lte"].forEach (o) ->
      if options[o] and isBuffer(options[o]) and options[o].length is 0
        delete options[o]
    if options.keys and isString(options.match) and options.match.length > 0
      @match = (item)->
        minimatch(item[0], options.match)
    if isFunction(options.filter)
      @filter = (item)->
        options.filter item[0], item[1]
    @encodeOptions options
    options

  encodeOptions: (options)->
  decodeResult: (result)->
  _next: (callback) ->
    self = this
    if @_nextSync
      setImmediate ->
        try
          result = self._nextSync()
          self._nexting = false
        catch e
          self._nexting = false
          callback e
          return
        if result
          callback null, result[0], result[1]
        else
          callback()
        return
    else
      setImmediate ->
        self._nexting = false
        callback()
        return


  _end: (callback) ->
    self = this
    if @_endSync
      setImmediate ->
        try
          result = self._endSync()
          callback null, result
        catch e
          callback e
    else
      setImmediate ->
        callback()


  nextKeysSync: ->
    @_nexting = true
    if @_indexOfKeys is -1
      @_resultOfKeys = @db._mGetSync @_resultOfKeys, @options
      @_indexOfKeys++
    result = @_indexOfKeys >= 0 and @_indexOfKeys < @_resultOfKeys.length
    if result
      result = @_resultOfKeys.slice(@_indexOfKeys, @_indexOfKeys+=2)
      @decodeResult result
      result =
        key: result[0]
        value: result[1]
    @_nexting = false
    return result

  nextSync: ->
    return throw new AlreadyEndError("cannot call next() after end()") if @_ended
    return throw new AlreadyRunError("cannot call next() before previous next() has completed") if @_nexting
    return false if @_filterStopped
    if @_indexOfKeys?
      return @nextKeysSync()
    else if @_nextSync
      @_nexting = true
      result = @_nextSync()
      if result isnt false
        @decodeResult result
        if @filter then switch @filter(result)
          when FILTER_EXCLUDED
            # skip this and read the next.
            @_nexting = false
            @nextSync()
            return
          when FILTER_STOPPED #halt
            @_filterStopped = true
        if @match and not @match(result)
          @_nexting = false
          @nextSync()
          return
        result =
          key: result[0]
          value: result[1]
        @last = result[0]
      @_nexting = false
      return result
    else
      throw new NotImplementedError()

  _endKeys: ->
    delete @_resultOfKeys
    @_indexOfKeys = -2
    # @_ended = true

  freeSync: ->
    if @_indexOfKeys?
      @_endKeys()
    if @_endSync
      @_ended = true
      return @_endSync()
    else
      throw new NotImplementedError()
  endSync: @::freeSync

  nextKeys: (callback) ->
    @_nexting = true
    if @_indexOfKeys is -1
      self = this
      @db._mGet @_resultOfKeys, @options, (err, arr)->
        self._nexting = false
        return callback(err) if err
        self._resultOfKeys = arr
        self._indexOfKeys++
        self.next(callback)
      return @
    else if @_indexOfKeys >= 0 and @_indexOfKeys < @_resultOfKeys.length
      result = @_resultOfKeys.slice(@_indexOfKeys, @_indexOfKeys+=2)
      @decodeResult result
      @_nexting = false
    else
      result = false
    @_nexting = false
    if result is false
      callback()
    else
      callback(undefined, result[0], result[1])
    @

  next: (callback) ->
    throw new InvalidArgumentError("next() requires a callback argument") unless typeof callback is "function"
    return callback(new AlreadyEndError("cannot call next() after end()")) if @_ended
    return callback(new AlreadyRunError("cannot call next() before previous next() has completed")) if @_nexting
    return callback() if @_filterStopped
    if @_indexOfKeys?
      @nextKeys callback
    else
      @_nexting = true
      self = this
      @_next (err, key, value)->
        self._nexting = false
        if !err and (key? or value?)
          result = [key, value]
          self.decodeResult result
          if self.filter then switch self.filter(result)
            when FILTER_EXCLUDED
              # skip this and read the next.
              self.next callback
              return
            when FILTER_STOPPED #halt
              self._filterStopped = true
          if self.match and not self.match(result)
            self.next callback
            return
          key = result[0]
          value = result[1]
          self.last = result[0]
        callback.apply null, arguments
    @

  free: (callback) ->
    throw new InvalidArgumentError("end() requires a callback argument")  unless typeof callback is "function"
    return callback(new AlreadyEndError("end() already called on iterator"))  if @_ended
    if @_indexOfKeys?
      @_endKeys()
    @_ended = true
    @_end callback
  end: @::free
