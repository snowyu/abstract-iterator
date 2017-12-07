### AbstractIterator [![Build Status](https://img.shields.io/travis/snowyu/abstract-iterator/master.svg)](http://travis-ci.org/snowyu/abstract-iterator) [![npm](https://img.shields.io/npm/v/abstract-iterator.svg)](https://npmjs.org/package/abstract-iterator) [![downloads](https://img.shields.io/npm/dm/abstract-iterator.svg)](https://npmjs.org/package/abstract-iterator) [![license](https://img.shields.io/npm/l/abstract-iterator.svg)](https://npmjs.org/package/abstract-iterator)


Add the iterator ability to the [abstract-nosql](https://github.com/snowyu/abstract-nosql) database.

* AbstractIterator(db[, options])
  * db: Provided with the current instance of [AbstractNoSql](https://github.com/snowyu/abstract-nosql).
  * options object(note: some options depend on the implementation of the Iterator)
    * `db`: the same with the db argument
    * `'next'`: the raw key data to ensure the readStream return keys is greater than the key. See `'last'` event.
      * note: this will affect the range[gt/gte or lt/lte(reverse)] options.
    * `'filter'` *(function)*: to filter data in the stream
      * function filter(key, value) if return:
        *  0(consts.FILTER_INCLUDED): include this item(default)
        *  1(consts.FILTER_EXCLUDED): exclude this item.
        * -1(consts.FILTER_STOPPED): stop stream.
      * note: the filter function argument 'key' and 'value' may be null, it is affected via keys and values of this options.
    * `'range'` *(string or array)*: the keys are in the give range as the following format:
      * string:
        * "[a, b]": from a to b. a,b included. this means {gte:'a', lte: 'b'}
        * "(a, b]": from a to b. b included, a excluded. this means {gt:'a', lte:'b'}
        * "[, b)" : from begining to b, begining included, b excluded. this means {lt:'b'}
        * "(, b)" : from begining to b, begining excluded, b excluded. this means {gt:null, lt:'b'}
        * note: this will affect the gt/gte/lt/lte options.
          * "(,)": this is not be allowed. the ending should be a value always.
      * array: the key list to get. eg, ['a', 'b', 'c']
        * `gt`/`gte`/`lt`/`lte` options will be ignored.
    * `'gt'` (greater than), `'gte'` (greater than or equal) define the lower bound of the range to be streamed. Only records where the key is greater than (or equal to) this option will be included in the range. When `reverse=true` the order will be reversed, but the records streamed will be the same.
    * `'lt'` (less than), `'lte'` (less than or equal) define the higher bound of the range to be streamed. Only key/value pairs where the key is less than (or equal to) this option will be included in the range. When `reverse=true` the order will be reversed, but the records streamed will be the same.
    * `'start', 'end'` legacy ranges - instead use `'gte', 'lte'`
    * `'match'` *(string)*: use the minmatch to match the specified keys.
      * Note: It will affect the range[gt/gte or lt/lte(reverse)] options maybe.
    * `'limit'` *(number, default: `-1`)*: limit the number of results collected by this stream. This number represents a *maximum* number of results and may not be reached if you get to the end of the data first. A value of `-1` means there is no limit. When `reverse=true` the highest keys will be returned instead of the lowest keys.
    * `'reverse'` *(boolean, default: `false`)*: a boolean, set true and the stream output will be reversed.
    * `'keys'` *(boolean, default: `true`)*: whether the `'data'` event should contain keys. If set to `true` and `'values'` set to `false` then `'data'` events will simply be keys, rather than objects with a `'key'` property.
    * `'values'` *(boolean, default: `true`)*: whether the `'data'` event should contain values. If set to `true` and `'keys'` set to `false` then `'data'` events will simply be values, rather than objects with a `'value'` property.

* next(callback): get the next key/value in the iterator async.
  * callback(err, key, value)
* nextSync(): return the next `{key, value}` object in the iterator.
* free():
* freeSync():
* end([callback]):
  * it's the alias for free method() to keep comaptiable with abstract-leveldown.
* endSync():
  * it's the alias for freeSync method() to keep comaptiable with abstract-leveldown.

The following internal methods need to be implemented:

## Sync methods:

### AbstractIterator#_nextSync()

Get the next element of this iterator.

__return__

* if any result: return a two elements of array
  * the first is the key, the first element could be null or undefined if options.keys is false
  * the second is the value, the second element could be null or undefined if options.values is false
* or return false, if no any data yet.


#### AbstractIterator#_endSync()

end the iterator.

### Async methods:

these async methods are optional to be implemented.

#### AbstractIterator#_next(callback)
#### AbstractIterator#_end(callback)

