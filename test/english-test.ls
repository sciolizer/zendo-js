assert = require('assert')
english = require('../src-js/english')

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

describe \run-print -> ``it``
  .. 'should print string as self' ->
    iterator = english.run-print \the, []
    item = iterator.next()
    assert.equal false, item.done
    assert.deepEqual <[the]>, item.value.strings
    assert.deepEqual [], item.value.stack
    item := iterator.next()
    assert.equal true, item.done
  .. 'should dump constant strings out as self' ->
    iterator = english.run-print <[the quick brown]>, []
    item = iterator.next()
    assert.equal false, item.done
    assert.deepEqual <[the quick brown]>, item.value.strings
    assert.deepEqual [], item.value.stack
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

describe \fold1 -> ``it``
  .. 'should sum the elements in a list' ->
    add = (x, y) -> x + y
    sum = english.fold1 add, [1, 2, 3]
    assert.equal 6, sum
  .. 'should evaluate from left to right' ->
    assert.equal -4, english.fold1( (-), [1, 2, 3])

describe \optionally-plural -> ``it``
  .. 'should parse plural' ->
    parser = english.optionally-plural \two
    iterator = english.run-parser parser, <[twos]>
    pt = new Parse-tester iterator
    pt.success [], [{two:{}}], []
    pt.done
  .. 'should parse singular' ->
    parser = english.optionally-plural \thank
    iterator = english.run-parser parser, <[a thank you]>
    pt = new Parse-tester iterator
    pt.error-expect \thanks
    pt.success [3, 4], [{thank:{}}, 3, 4], <[you]>
    pt.done

describe \map -> ``it``
  .. 'should increment numbers' ->
    inc = (x) -> x + 1
    mapped = english.map inc, [1, 2, 3]
    assert.deepEqual [2, 3, 4], mapped

describe \rank-g -> ``it``
  .. 'should parse aces' ->
    iterator = english.run-parser english.rank-g, <[aces]>
    pt = new Parse-tester iterator
    pt.success [1], [{ace:{}}, 1]
  .. 'should parse a two' ->
    iterator = english.run-parser english.rank-g, <[a two]>
    pt = new Parse-tester iterator
    pt.error-expect "aces"
    pt.error-expect "an"
    pt.error-expect "twos"
    pt.success [], [{two:{}}]

describe 'run-print function' -> ``it``
  boomerang =
    print: (stack) ->*
      if stack.length > 0 && stack[0] == 7
        yield do
          strings: <[cool yo]>
          stack: stack.slice(1)
  .. 'should call my print function' ->
    iterator = english.run-print boomerang, [7]
    item = iterator.next()
    assert.equal item.done, false
    assert.deepEqual item.value.strings, <[cool yo]>
    assert.deepEqual item.value.stack, []
    item := iterator.next()
    assert.equal item.done, true
  .. 'should give nothing if wrong stack' ->
    iterator = english.run-print boomerang, [6]
    item = iterator.next()
    assert.equal true, item.done

describe 'pure print' -> ``it``
  reducer = (left, right) -> { left, right }
  expander = (item) -> if item && item.left && item.right then [item.left, item.right] else void
  boomerang = english.pure reducer, expander
  .. 'pop stack on match' ->
    iterator = english.run-print boomerang, [{ left: 3, right: 4 }]
    item = iterator.next()
    assert.equal item.done, false
    assert.deepEqual item.value.strings, []
    assert.deepEqual item.value.stack, [3, 4]
    item := iterator.next()
    assert.equal item.done, true
  .. 'fail on empty stack' ->
    iterator = english.run-print boomerang, []
    item = iterator.next()
    assert.equal item.done, true
  .. 'fail on stack with wrong item' ->
    iterator = english.run-print boomerang, [{ hello: \sugar }]
    item = iterator.next()
    assert.equal item.done, true
  .. 'print multiple options' ->
    iterator = english.run-print([\fancy, boomerang] `english.o` \bland, [{ left: 3, right: 4 }])
    item = iterator.next()
    assert.equal item.done, false
    assert.deepEqual item.value.strings, <[fancy]>
    assert.deepEqual item.value.stack, [3, 4]
    item := iterator.next()
    assert.equal item.done, false
    assert.deepEqual item.value.strings, <[bland]>
    assert.deepEqual item.value.stack, [{ left: 3, right: 4}]
    item := iterator.next()
    assert.equal item.done, true
  .. 'print only the possible option' ->
    iterator = english.run-print([\fancy, boomerang] `english.o` \bland, [])
    item = iterator.next()
    assert.equal item.done, false
    assert.deepEqual item.value.strings, <[bland]>
    assert.deepEqual item.value.stack, []
    item := iterator.next()
    assert.equal item.done, true

describe 'print choice' -> ``it``
  .. 'print both options' ->
    iterator = english.run-print(\a `english.o` \the, [])
    item = iterator.next()
    assert.equal item.done, false
    assert.deepEqual item.value.strings, <[a]>
    assert.deepEqual item.value.stack, []
    item := iterator.next()
    assert.equal item.done, false
    assert.deepEqual item.value.strings, <[the]>
    assert.deepEqual item.value.stack, []
    item := iterator.next()
    assert.equal item.done, true

describe 'more pure' -> ``it``
  color-boomerang = english.pure(-> { red: {} }, (color) -> if color && color.red then [] else void)
  .. 'no-arg pure' ->
    iterator = english.run-parser color-boomerang, <[roy gee]>
    pt = new Parse-tester iterator
    pt.success [3, 4], [{red:{}}, 3, 4], <[roy gee]>
    pt.done
  .. 'two pures back to back' ->
    property-boomerang = english.pure((color) -> { isColor: { color } }, (property) -> if property && property.isColor then [property.isColor.color] else void)
    iterator = english.run-parser [property-boomerang, color-boomerang, \red], <[red]>
    pt = new Parse-tester iterator
    pt.success [], [ { isColor: { color: { red: {} } } } ], []
    pt.done

describe \red -> ``it``
  .. 'should become a color via color-g' ->
    iterator = english.run-parser english.color-g, <[red medallion]>
    pt = new Parse-tester iterator
    pt.success [], [ { red: {} } ], <[medallion]>
    pt.done
  .. 'should become a property via constructors' ->
    parser = [english.pure(english.color-constructor, english.deconstruct-color), english.color-g]
    iterator = english.run-parser parser, <[red medallion]>
    pt = new Parse-tester iterator
    pt.success [], [{isColor:{color:{red:{}}}}], <[medallion]>
    pt.done
  .. 'should become a property via any constructors' ->
    parser = english.any [[english.pure(english.color-constructor, english.deconstruct-color), english.color-g]]
    iterator = english.run-parser parser, <[red medallion]>
    pt = new Parse-tester iterator
    pt.success [], [{isColor:{color:{red:{}}}}], <[medallion]>
    pt.done
/*
  .. 'should become a property via color-g' ->
    iterator = english.run-parser english.property-g, <[red medallion]>
    pt = new Parse-tester iterator
    pt.success [], [{isColor:{color:{red:{}}}}], <[medallion]>
    pt.done
*/

describe \any -> ``it``
  .. 'should do the thing on a singleton list' ->
    iterator = english.run-parser(english.any([\red]), <[red medallion]>)
    pt = new Parse-tester iterator
    pt.success [], [], <[medallion]>
    pt.done
  .. 'should attempt the first option' ->
    iterator = english.run-parser(english.any(<[red black]>), <[red medallion]>)
    pt = new Parse-tester iterator
    pt.success [], [], <[medallion]>
    pt.error-expect \black, <[red medallion]>
    pt.done
  .. 'should attempt the second option' ->
    iterator = english.run-parser(english.any(<[red black]>), <[black medallion]>)
    pt = new Parse-tester iterator
    pt.error-expect \red, <[black medallion]>
    pt.success [], [], <[medallion]>
    pt.done
  .. 'should not consume when none of them work' ->
    iterator = english.run-parser(english.any(<[red black]>), <[purple medallion]>)
    pt = new Parse-tester iterator
    pt.error-expect \red, <[purple medallion]>
    pt.error-expect \black, <[purple medallion]>
    pt.done

class Parse-tester
  (@iterator) ->
  error-expect: (expected, strings) ->
    item = @iterator.next()
    assert.equal false, item.done
    assert.equal true, item.value.error
    if expected != void
      assert.equal expected, item.value.expected
    if strings != void
      assert.deepEqual strings, item.value.strings
  success: (stack-input, stack-output, strings) ->
    item = @iterator.next()
    assert.equal false, item.done
    if item.value.error
      assert.fail "error, unexpected: " + item.value.expected, "successful parse", "expected successful parse, actual error expecting: " + item.value.expected, "next"
    if void != strings
      assert.deepEqual strings, item.value.strings
    if void != stack-input
      new-stack = item.value.stack-modifier(stack-input)
      assert.deepEqual stack-output, new-stack
  done: ->
    item = @iterator.next()
    assert.equal true, item.done

#describe 'pure and run-parse' -> ``it``
  #.. 'should concatenate the input' ->
    #reducer = (left, right) -> 



    # todo: ambiguous parses
