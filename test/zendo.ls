require! assert
z = require \../js-src/zendo

describe \partial-translations -> ``it``
  .. 'should make suggestions for the empty string' ->
    translation = z.translate ''
    assert.equal translation.understood, 0
    assert.deepEqual translation.suggestions, <[a all any at each every one]>
    assert.deepEqual translation.paraphrases, []
    assert.equal translation.rule, void
  .. 'should make suggestions for a string of one space' ->
    translation = z.translate ' '
    assert.equal translation.understood, 0
    assert.deepEqual translation.suggestions, <[a all any at each every one]>
    assert.deepEqual translation.paraphrases, []
    assert.equal translation.rule, void
  .. 'should make suggestions for a string of two spaces' ->
    translation = z.translate '  '
    assert.equal translation.understood, 0
    assert.deepEqual translation.suggestions, <[a all any at each every one]>
    assert.deepEqual translation.paraphrases, []
    assert.equal translation.rule, void
  .. 'should suggest only words beginning with a' ->
    translation = z.translate \a
    assert.equal translation.understood, 1
    assert.deepEqual translation.suggestions, <[<space> all any at]>
    assert.deepEqual translation.paraphrases, []
    assert.equal translation.rule, void
  .. 'should suggest more words after the space' ->
    translation = z.translate 'a '
    assert.equal translation.understood, 1
    assert.deepEqual translation.suggestions, <[card]>
    assert.deepEqual translation.paraphrases, []
    assert.equal translation.rule, void
  .. 'should suggest only card after a c' ->
    translation = z.translate 'a c'
    assert.equal translation.understood, 1
    assert.deepEqual translation.suggestions, <[card]>
    assert.deepEqual translation.paraphrases, []
    assert.equal translation.rule, void
  .. 'should suggest only card after a car' ->
    translation = z.translate 'a car'
    assert.equal translation.understood, 1
    assert.deepEqual translation.suggestions, <[card]>
    assert.deepEqual translation.paraphrases, []
    assert.equal translation.rule, void
  .. 'should suggest nothing after a b' ->
    translation = z.translate 'a b'
    assert.equal translation.understood, 1
    assert.deepEqual translation.suggestions, []
    assert.deepEqual translation.paraphrases, []
    assert.equal translation.rule, void
  .. 'should suggest only <space> after a card' ->
    translation = z.translate 'a card'
    assert.equal translation.understood, 2
    assert.deepEqual translation.suggestions, <[<space>]>
    assert.deepEqual translation.paraphrases, []
    assert.equal translation.rule, void
  .. 'should suggest words after a card <space>' ->
    translation = z.translate 'a card '
    assert.equal translation.understood, 2
    assert.deepEqual translation.suggestions, <[is]>
    assert.deepEqual translation.paraphrases, []
    assert.equal translation.rule, void
  .. 'should suggest words after a card <multiple spaces>' ->
    translation = z.translate 'a card  '
    assert.equal translation.understood, 2
    assert.deepEqual translation.suggestions, <[is]>
    assert.deepEqual translation.paraphrases, []
    assert.equal translation.rule, void
  .. 'should suggest only all for al' ->
    translation = z.translate 'al'
    assert.equal translation.understood, 0
    assert.deepEqual translation.suggestions, <[all]>
    assert.deepEqual translation.paraphrases, []
    assert.equal translation.rule, void
  .. 'should suggest nothing for al and a space' ->
    translation = z.translate 'al '
    assert.equal translation.understood, 0
    assert.deepEqual translation.suggestions, []
    assert.deepEqual translation.paraphrases, []
    assert.equal translation.rule, void

describe \complete-translations -> ``it``
  .. 'should consider a card is black to be a rule' ->
    translation = z.translate 'a card is black'
    assert.equal translation.understood, 4
    assert.deepEqual translation.suggestions, <[<enter> <space>]>
    assert.deepEqual translation.paraphrases, ['a card is black', 'any card is black', 'at least one card is black', 'at least one of the cards is black', 'one card is black', 'one of the cards is black']
    assert.deepEqual translation.rule, [atLeastOne:{property:{isColor:{color:{black:{}}}}}]

/*
suggest <enter> even when last character is not a space
random-rule - just do a pretty-print and make sure it has at least one output 
suggest <space>
before space is entered, most recent characters must be prefix of all suggestions
no duplicate paraphrases
no duplicate word suggestions
*/

describe \Game -> ``it``
  .. 'should mark the all red koan as true' ->
    game = new z.Game({all:{property:{isColor:{color:{red:{}}}}}})
    assert.equal game.mark-koan(["2H", "TD"]), true
  .. 'should generate counter example' ->
    game = new z.Game({all:{property:{isColor:{color:{red:{}}}}}})
    result = game.evaluate-rule({atLeastOne:{property:{isColor:{color:{red:{}}}}}})
    assert(result.counterExample.length != 1, "" + result.counterExample.length + " != 1")
  .. 'should return win for identical rules' ->
    game = new z.Game({all:{property:{isColor:{color:{red:{}}}}}})
    result = game.evaluate-rule({all:{property:{isColor:{color:{red:{}}}}}})
    assert.deepEqual result.win, {}
