require! \assert
b = require \boomerang-grammar

english = require('../js-src/english')

describe \optionally-plural -> ``it``
  .. 'should parse plural' ->
    parser = english.optionally-plural \two
    iterator = b.parse parser, <[twos]>
    pt = new Parse-tester iterator
    pt.success [], [{two:{}}], []
    pt.done
  .. 'should parse singular' ->
    parser = english.optionally-plural \thank
    iterator = b.parse parser, <[a thank you]>
    pt = new Parse-tester iterator
    pt.error-expect \thanks
    pt.success [3, 4], [{thank:{}}, 3, 4], <[you]>
    pt.done

describe \rank-g -> ``it``
  .. 'should parse aces' ->
    iterator = b.parse english.rank-g, <[aces]>
    pt = new Parse-tester iterator
    pt.success [1], [{ace:{}}, 1]
  .. 'should parse a two' ->
    iterator = b.parse english.rank-g, <[a two]>
    pt = new Parse-tester iterator
    pt.error-expect "aces"
    pt.error-expect "an"
    pt.error-expect "twos"
    pt.success [], [{two:{}}]

describe \red -> ``it``
  .. 'should become a color via color-g' ->
    iterator = b.parse english.color-g, <[red medallion]>
    pt = new Parse-tester iterator
    pt.success [], [ { red: {} } ], <[medallion]>
    pt.done
  .. 'should become a property via constructors' ->
    parser = [b.pure(english.color-constructor, english.deconstruct-color), english.color-g]
    iterator = b.parse parser, <[red medallion]>
    pt = new Parse-tester iterator
    pt.success [], [{isColor:{color:{red:{}}}}], <[medallion]>
    pt.done
  .. 'should become a property via any constructors' ->
    parser = b.any [[b.pure(english.color-constructor, english.deconstruct-color), english.color-g]]
    iterator = b.parse parser, <[red medallion]>
    pt = new Parse-tester iterator
    pt.success [], [{isColor:{color:{red:{}}}}], <[medallion]>
    pt.done
/*
  .. 'should become a property via color-g' ->
    iterator = b.parse english.property-g, <[red medallion]>
    pt = new Parse-tester iterator
    pt.success [], [{isColor:{color:{red:{}}}}], <[medallion]>
    pt.done
*/

describe \example-rule -> ``it``
  .. 'should parse a card is black' ->
    parser = english.rule-g
    iterator = b.parse parser, <[a card is black]>
    item = iterator.next()
    value = void
    while not item.done
      if not item.value.error
        value = item.value
        break
      item := iterator.next()
    assert.equal value.strings.length, 0
    stack = value.stack-modifier []
    assert.deepEqual stack, [{atLeastOne:{property:{isColor:{color:{black:{}}}}}}]

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
