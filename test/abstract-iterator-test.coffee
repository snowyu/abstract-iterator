chai            = require 'chai'
sinon           = require 'sinon'
sinonChai       = require 'sinon-chai'
should          = chai.should()
expect          = chai.expect
chai.use(sinonChai)

AbstractIterator= require '../src/abstract-iterator'
inherits        = require 'inherits-ex/lib/inherits'
setImmediate    = setImmediate || process.nextTick

describe 'AbstractIterator', ->
    #before (done)->
    #after (done)->
    describe 'constructor', ->
      it 'default constructor', ->
        iterator = new AbstractIterator
        iterator.should.have.ownProperty 'options'
        iterator.options.should.be.deep.equal
          reverse: false
          keys: true
          values: true
          limit: -1
          keyAsBuffer: false
          valueAsBuffer: false
        iterator.should.have.property '_ended', false
        iterator.should.have.property '_nexting', false
        iterator.should.not.have.property '_resultOfKeys'
        iterator.should.not.have.property '_indexOfKeys'
      it 'should apply option range (1,2)', ->
        db = {}
        iterator = new AbstractIterator db, range:'(1,2)'
        iterator.should.have.ownProperty 'options'
        iterator.options.should.have.property 'gt', '1'
        iterator.options.should.have.property 'lt', '2'

