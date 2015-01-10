assert = require('assert')
english = require('../js/english')

describe \something -> ``it``
  .. 'should be 5' ->
    assert.equal(english.something, 5)

describe 'run-parser words and arrays' -> ``it``
  .. "should parse 'the' as the identity function" ->
    iterator = english.run-parser \the <[the]>
    item = iterator.next()
    assert.equal false, item.done
    assert.deepEqual [], item.value.strings
    assert.deepEqual [3, 7], item.value.stack-modifier([3, 7])
    item := iterator.next()
    assert.equal true, item.done
  .. "should parse 'the quick' as the identity function" ->
    iterator = english.run-parser <[the quick]> <[the quick]>
    item = iterator.next()
    assert.equal false, item.done
    assert.deepEqual [], item.value.strings
    assert.deepEqual [3, 7], item.value.stack-modifier([3, 7])
    item := iterator.next()
    assert.equal true, item.done
  .. "should parse 'ye' as an error" ->
    iterator = english.run-parser \the <[ye]>
    item = iterator.next()
    assert.equal false, item.done
    assert.equal \the, item.value.expected
    item := iterator.next()
    assert.equal true, item.done
  .. "should parse 'the slow' as an error" ->
    iterator = english.run-parser <[the quick]> <[the slow]>
    item = iterator.next()
    assert.equal false, item.done
    assert.equal \quick, item.value.expected
    item := iterator.next()
    assert.equal true, item.done

describe 'run-parser functions' -> ``it``
  .. 'should invoke custom parse function' ->
    custom-parser =
      parse: (strings) ->*
        yield do
          strings: strings
          stackModifier: (stack) -> [3] ++ stack
    iterator = english.run-parser custom-parser, <[the quick]>
    item = iterator.next()
    assert.equal false, item.done
    assert.deepEqual <[the quick]>, item.value.strings
    assert.deepEqual [3,4], item.value.stack-modifier([4])
    item := iterator.next()
    assert.equal true, item.done

describe 'pure' -> ``it``
  .. 'should consume the right number of stack entries' ->
    reducer = (a, b, c) -> a + b + c
    parser = english.pure reducer
    iterator = parser.parse <[the quick]>
    item = iterator.next()
    assert.equal false, item.done
    assert.deepEqual <[the quick]>, item.value.strings
    assert.deepEqual [6, 4, 5], item.value.stack-modifier([1, 2, 3, 4, 5])
    item = iterator.next()
    assert.equal true, item.done
  .. 'should always return at least one value' ->
    reducer = (a, b, c) -> a + b + c
    parser = english.pure reducer
    iterator = parser.parse <[the quick]>
    item = iterator.next()
    assert.equal false, item.done
    assert.deepEqual <[the quick]>, item.value.strings
    assert.deepEqual [6], item.value.stack-modifier([1, 2, 3])
    item = iterator.next()
    assert.equal true, item.done
  .. 'should throw error on stack depletion' ->
    reducer = (a, b, c) -> a + b + c
    parser = english.pure reducer
    iterator = parser.parse <[the quick]>
    item = iterator.next()
    assert.equal false, item.done
    assert.deepEqual <[the quick]>, item.value.strings
    try
      item.value.stack-modifier [1,2]
      assert.fail 'stack-modifier did not throw exception'
    catch {message}
      assert.equal 'grammar bug: stack depleted', message
    assert.deepEqual [6], item.value.stack-modifier([1, 2, 3])
    item := iterator.next()
    assert.equal true, item.done

describe 'choice' -> ``it``
  .. 'should parse choices' ->
    parser = 'here' `english.o` 'there'
    iterator = parser.parse <[here boy]>
    item = iterator.next()
    assert.equal false, item.done
    assert.deepEqual [\boy], item.value.strings
    assert.deepEqual [3,4], item.value.stack-modifier([3,4])
    item := iterator.next()
    assert.equal false, item.done
    assert.deepEqual <[here boy]>, item.value.strings
    assert.equal true, item.value.error
    assert.equal \there, item.value.expected
    item := iterator.next()
    assert.equal true, item.done
  .. 'constant after choice' ->
    parser = ['a' `english.o` 'the', 'quick']
    iterator = english.run-parser parser, <[the quick]>
    item = iterator.next()
    assert.equal false, item.done
    assert.deepEqual <[the quick]>, item.value.strings
    assert.equal true, item.value.error
    assert.equal \a, item.value.expected
    item := iterator.next()
    assert.equal false, item.done
    assert.deepEqual [], item.value.strings
    assert.deepEqual [3,4], item.value.stack-modifier([3,4])
    item := iterator.next()
    assert.equal true, item.done
  .. 'constant before choice' ->
    parser = ['the', 'quick' `english.o` 'slow']
    iterator = english.run-parser parser, <[the slow]>
    item = iterator.next()
    assert.equal false, item.done
    assert.deepEqual <[slow]>, item.value.strings
    assert.equal true, item.value.error
    assert.equal \quick, item.value.expected
    item := iterator.next()
    assert.equal false, item.done
    assert.deepEqual [], item.value.strings
    assert.deepEqual [3,4], item.value.stack-modifier([3,4])
    item := iterator.next()
    assert.equal true, item.done
  .. 'chained choices' ->
    parser = ['a' `english.o` 'the', 'quick' `english.o` 'slow']
    iterator = english.run-parser parser, <[the slow]>
    item = iterator.next()
    assert.equal false, item.done
    assert.deepEqual <[the slow]>, item.value.strings
    assert.equal true, item.value.error
    assert.equal \a, item.value.expected
    item := iterator.next()
    assert.equal false, item.done
    assert.deepEqual <[slow]>, item.value.strings
    assert.equal true, item.value.error
    assert.equal \quick, item.value.expected
    item := iterator.next()
    assert.equal false, item.done
    assert.deepEqual [], item.value.strings
    assert.deepEqual [3,4], item.value.stack-modifier([3,4])
    item := iterator.next()
    assert.equal true, item.done

describe 'mini-parse' -> ``it``
  .. 'should push a number' ->
    mini-parser = (i) ->
      parsed = parseInt i
      if isNaN parsed then void else parsed
    parser = english.mini-parse mini-parser, "<number>"
    iterator = parser.parse <[3 chimpanzees]>
    item = iterator.next()
    assert.equal false, item.done
    assert.deepEqual <[chimpanzees]>, item.value.strings
    assert.deepEqual [3, 4], item.value.stack-modifier(4)
    item := iterator.next()
    assert.equal true, item.done
  .. 'should fail on an empty string' ->
    mini-parser = (i) ->
      parsed = parseInt i
      if isNaN parsed then void else parsed
    parser = english.mini-parse mini-parser, "<number>"
    iterator = parser.parse []
    item = iterator.next()
    assert.equal false, item.done
    assert.deepEqual [], item.value.strings
    assert.equal true, item.value.error
    assert.equal "<number>", item.value.expected
    item := iterator.next()
    assert.equal true, item.done
  .. 'should fail on mini-parse failure' ->
    mini-parser = (i) ->
      parsed = parseInt i
      if isNaN parsed then void else parsed
    parser = english.mini-parse mini-parser, "<number>"
    iterator = parser.parse <[hockey puck]>
    item = iterator.next()
    assert.equal false, item.done
    assert.deepEqual <[hockey puck]>, item.value.strings
    assert.equal true, item.value.error
    assert.equal "<number>", item.value.expected
    item := iterator.next()
    assert.equal true, item.done

describe 'nop' -> ``it``
  .. 'should leave things as they are' ->
    iterator = english.nop.parse <[no touchy]>
    item = iterator.next()
    assert.equal false, item.done
    assert.deepEqual <[no touchy]>, item.value.strings
    assert.deepEqual [3,4], item.value.stack-modifier([3,4])
    item := iterator.next()
    assert.equal true, item.done
#describe 'pure and run-parse' -> ``it``
  #.. 'should concatenate the input' ->
    #reducer = (left, right) -> 



    # todo: ambiguous parses
