b = require \boomerang-grammar
ev = require \./evaluate
e = require \./english
r = require \./random

/*
type Card = String -- e.g. 2C, 7H, AD, JC, QH, KS, TH
*/

class Game
  (@solution, @rand) ->
    # @solution is a rule, e.g. from random-rule
    if @rand == void
      @rand = { next: (cap) -> Math.floor(Math.random() * cap) }
  mark-koan: (cards) ->
    ev.evaluate-top @solution, cards
  evaluate-rule: (rule) ->
    for x from 1 to 1000
      size = @rand.next(4) # exp dropoff?
      cards = []
      for y from 0 til size
        cards.push("A23456789TJQK"[@rand.next(13)] + "CDHS"[@rand.next(4)])
      under-their-rule = ev.evaluate-top @solution, cards
      under-correct-rule = ev.evaluate-top rule, cards
      if under-their-rule != under-correct-rule
        return { counterExample: cards }
    return { win: {} }

translate = (rule) ->
  strings = rule.trim().split(/\s+/)
  is-new-word = rule.slice(-1) == ' ' && rule.trim().length > 0
  top-rule = e.rule-g
  iterator = b.parse top-rule, strings
  words = []
  item = iterator.next()
  stacks = []
  understood = 0
  while not item.done
    diff = strings.length - item.value.strings.length
    if diff > understood
      understood := diff
    if item.value.strings.length == 0
      if item.value.error
        expected = item.value.expected
        if expected == "<eof>"
          throw new Error("impossible") # this line should be unreachable
        else
          if is-new-word
            if words.indexOf(expected) == -1
              words.push expected
          else
            if words.indexOf(\<space>) == -1
              words.push \<space>
      else
        new-stack = item.value.stack-modifier([])
        stacks.push(new-stack)
        if words.indexOf("<enter>") == -1
          words.push "<enter>"
    else if item.value.strings.length == 1
      unparsed = item.value.strings[0]
      if item.value.error
        expected = item.value.expected
        if not is-new-word
          if expected.indexOf(unparsed) == 0
            if words.indexOf(expected) == -1
              words.push expected
    item := iterator.next()
  if stacks.length > 1
    console.log \stacks, stacks
  other-sentences = []
  if stacks.length > 0
    stack = stacks[0]
    iterator = b.print top-rule, stack
    item = iterator.next()
    while not item.done
      sentence = item.value.strings.join " "
      if other-sentences.indexOf(sentence) == -1
        other-sentences.push(sentence)
      item := iterator.next()
  words.sort()
  other-sentences.sort()
  do
    understood: understood # number of understood words
    suggestions: words # words which can be added to the provided rule
    paraphrases: other-sentences # other ways of saying the same thing
    rule: stack # the rule to be passed to the game class

module.exports =
  Game: Game
  randomRule: r.random-rule
  translate: translate
