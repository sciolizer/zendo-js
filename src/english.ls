
# todo: figure out how to import the prelude
map = (f, list) ->
  result = []
  for item in list
    result.push(f(item))
  result

single = (f) -> (item) -> [f(item)]

optionally-plural = (word) ->
  plural = if word == \six then \sixes else word + \s
  article = if word == \ace then \an else \a
  deconstruct-word = (thing) -> if thing and thing[word] then [] else void
  [pure(-> { "#word": {} }, deconstruct-word), plural `o` [article, word]]

o = (left, right) ->
  parse: (strings) ->*
    yield from run-parser(left, strings)
    yield from run-parser(right, strings)
  debug: ->
    "o(" + run-debug(left) + "," + run-debug(right) + ")"
  print: (stack) ->*
    yield from run-print(left, stack)
    yield from run-print(right, stack)

# todo: figure out how to import the prelude
fold1 = (f, list) ->
  result = list[0]
  for next in list.slice(1)
    result := f result, next
  result

any = (choices) -> fold1 o, choices

opt = (parser) -> nop `o` parser

nop =
  parse: (strings) ->*
    yield do
      strings: strings
      stackModifier: (stack) -> stack
  debug: ->
    "nop"
  print: (stack) ->*
    yield do
      strings: []
      stack: stack

# Input:
#   parser: a boomerang
#   strings: input remaining to be parsed
# Output: generator of
#   strings: input remaining to be parsed
#   stackModifier: parsed value :: [] -> []. Stack may grow, shrink, or stay the same.
#   error: true or undefined. stackModifier is undefined when true
#   expected: in an error, the string that was expected to be next
run-parser = (parser, strings) ->*
  switch parser.constructor
  case String
    if strings.length > 0 && strings[0] == parser
      yield do
        strings: strings.slice(1)
        stackModifier: (result) -> result
    else
      yield do
        strings: strings
        expected: parser
        error: true
  case Array
    yield from run-array-parser(parser, strings)
  case Object
    yield from parser.parse(strings)
  default ...

run-print = (parser, stack) ->*
  switch parser.constructor
  case String
    yield do
      strings: [parser]
      stack: stack
  case Array
    yield from run-array-print parser, stack
  case Object
    yield from parser.print stack
  default ...

run-debug = (parser) ->
  if void == parser
    return "void"
  switch parser.constructor
  case String
    parser
  case Array
    map run-debug, parser
  case Object
    parser.debug()
  default
    "unknown"

# Input:
#   array: an array of boomerangs
#   strings: input remaining to be parsed.
# Output: same as for run-parser
run-array-parser = (array, strings) ->*
  if array.length == 0
    yield do
      strings: strings
      stackModifier: (result) -> result
  else
    head-iterator = run-parser(array[0], strings)
    head-item = head-iterator.next()
    while not head-item.done
      if head-item.value.error
        yield head-item.value
      else
        tail-iterator = run-array-parser(array.slice(1), head-item.value.strings)
        tail-item = tail-iterator.next()
        while not tail-item.done
          if tail-item.value.error
            yield tail-item.value
          else
            yield do
              strings: tail-item.value.strings
              stackModifier: head-item.value.stack-modifier << tail-item.value.stack-modifier
          tail-item := tail-iterator.next()
      head-item := head-iterator.next()

run-array-print = (array, stack) ->*
  if array.length == 0
    yield do
      strings: []
      stack: stack
  else
    head-iterator = run-print array[0], stack
    head-item = head-iterator.next()
    while not head-item.done
      tail-iterator = run-array-print array.slice(1), head-item.value.stack
      tail-item = tail-iterator.next()
      while not tail-item.done
        yield do
          strings: head-item.value.strings ++ tail-item.value.strings
          stack: tail-item.value.stack
        tail-item := tail-iterator.next()
      head-item := head-iterator.next()

# Input:
#   reducer: any function with a fixed number of arguments
#   expander: function of one argument that returns a list of stack items, or returns void.
#     Generaly the size of the list will match the number of arguments on reducer
# Output:
#   a boomerang which consumes no input and applies the function to the current stack
pure = (reducer, expander) ->
  parse: (strings) ->*
    yield do
      strings: strings
      stackModifier: (stack) ->
        if stack.length < reducer.length
          #console.log "depleted stack", stack
          #console.log "reducer", reducer
          throw Error 'grammar bug: stack depleted'
        args = stack.slice 0, reducer.length
        [reducer.apply @, args] ++ stack.slice reducer.length
  debug: ->
    "pure"
  print: (stack) ->*
    if stack.length > 0
      prefix = expander(stack[0])
      if prefix != void
        yield do
          strings: []
          stack: prefix ++ stack.slice(1)

# Input:
#   mini-parser: a function which takes a string and returns a value.
#     Returning undefined indicates the parse failed.
#   expected: the string to display to the user on parse failure, e.g. "<number>"
mini-parse = (mini-parser, expected, to-string) ->
  parse: (strings) ->*
    if strings.length > 0
      val = mini-parser strings[0]
      if val == void
        yield do
          strings: strings
          error: true
          expected: expected
      else
        yield do
          strings: strings.slice 1
          stackModifier: (stack) -> [val] ++ stack
    else
      yield do
        strings: strings
        error: true
        expected: expected
  debug: ->
    "mini-parse(" + expected + ")"
  print: (stack) ->*
    yield do
      strings: if to-string == void then "" + stack[0] else to-string(stack[0])
      stack: stack.slice(1)

on-rule-input-change = ->
  rule-input = $ '#rule-input'
  next-words-list = $ '#next-words-list'
  line = rule-input.val()
  strings = line.trim().split(/\s+/)
  if line.slice(-1) != " "
    last-word = strings.slice(-1)[0]
    strings = strings.slice(0, -1)
  else
    last-word = ""
  if strings.length == 0 && strings[0] == ""
    strings = []
  top-rule = rule-g
  iterator = run-parser top-rule, strings
  words = []
  item = iterator.next()
  stacks = []
  while not item.done
    if item.value.error && item.value.strings.length == 0
      expected = item.value.expected
      if expected.indexOf(last-word) == 0 && words.indexOf(expected) == -1
        words.push expected
    else if not item.value.error
      new-stack = item.value.stack-modifier([])
      stacks.push(new-stack)
      if words.indexOf("&lt;enter&gt;") == -1
        words.push "&lt;enter&gt;"
    item := iterator.next()
  other-sentences = []
  for stack in stacks
    iterator = run-print top-rule, stack
    item = iterator.next()
    while not item.done
      sentence = item.value.strings.join " "
      if other-sentences.indexOf(sentence) == -1
        other-sentences.push(sentence)
      item := iterator.next()
  words.sort()
  html = ""
  for word in words
    html := html + " #word" #<li class='list-group-item'>#word</li>"
  next-words-list.html(html)
  interpretations-html = ""
  other-sentences.sort()
  for sentence in other-sentences
    interpretations-html := interpretations-html + "<li class='list-group-item'>#sentence</li>"
  $('#other-interpretations').html(interpretations-html)

rule =
  and: { left: \rule, right: \rule }
  atLeastOne: { property: \property }
  all: { property: \property }

#none = <[none of the numbers are]> `o` <[no number is]>
#sum = ['the', 'sum' `o` 'total', opt(<[of the numbers]>), 'is']
#smallest = ['the', ('smallest' `o` 'minimum') `o` 'least', opt('number'), 'is']
#largest = ['the', ('largest' `o` 'biggest') `o` 'maximum', opt('number'), 'is']
#first = ['the', 'first', opt('number'), 'is']
#last = ['the', 'last', opt('number'), 'is']
#of-numbers = <[of numbers]>

property =
  isColor: { color: \color }
  hasSuit: { suit: \suit }
  isRank: { rank: \rank }
  isFace: {}

rank-g = any(map optionally-plural, <[ace two three four five seven eight nine ten jack queen king]>)

suit-g = any(map optionally-plural, <[heart club diamond spade]>)

deconstruct-red = (color) -> if color and color.red then [] else void

deconstruct-black = (color) -> if color and color.black then [] else void

red-constructor = ->
  { red: {} }

black-constructor = ->
  { black: {} }

color-g = [pure(-> { red: {} }, deconstruct-red), \red] `o` [pure(-> { black: {} }, deconstruct-black), \black]

deconstruct-color = (property) ->
  if property && property.isColor && property.isColor.color
    [property.isColor.color]

color-constructor = (color) ->
  { isColor: { color } }

property-g = any do
  * [pure(color-constructor, deconstruct-color), color-g]
    [pure((suit) -> { hasSuit: { suit } }, single((?.hasSuit?.suit))), suit-g]
    [pure((rank) -> { isRank: { rank } }, single((?.isRank?.rank))), rank-g]

/*
color =
  red: {}
  black: {}
*/

/*
suit =
  hearts: {}
  clubs: {}
  diamonds: {}
  spades: {}
*/


/*
rank =
  ace: {}
  two: {}
  three: {}
  four: {}
  five: {}
  six: {}
  seven: {}
  eight: {}
  nine: {}
  ten: {}
  jack: {}
  queen: {}
  king: {}
*/

deconstruct-all = (rule) -> if rule and rule.all and rule.all.property then [rule.all.property] else void

all-construct = (property) ->
  { all: { property } }
each-and-every-g = ['each', opt(<[and every]>)] `o` 'every'
all-g = [pure(all-construct, deconstruct-all), [each-and-every-g, 'card', 'is'] `o` <[all cards are]>, property-g]
at-least-one-g = [pure((property) -> { atLeastOne: { property } }, single((?.atLeastOne?.property))), [opt(['at', 'least']), 'one', <[of the cards]> `o` 'card', 'is'] `o` ['a' `o` 'any', 'card', 'is'], property-g]

and-deconstructor = (rule) ->
  left = rule?.and?.left
  right = rule?.and?.right
  if left != void && right != void
    [left, right]

recurse = (boomerang-supplier) ->
  parse: (strings) ->*
    yield from run-parser(boomerang-supplier(), strings)
  debug: ->
    "recurse"
  print: (stack) ->*
    yield from run-print(boomerang-supplier(), stack)


quantifier-g = any [all-g, at-least-one-g]

and-g = [pure((left, right) -> { and: { left, right } }, and-deconstructor), quantifier-g, \and, recurse(-> rule-g)]

rule-g = any [quantifier-g, and-g]

/*
rule-dictionary = { rule, property, color, suit, rank }

data Rule
  = And Rule Rule
  | Or Rule Rule
  | Not Rule
  | AtLeastOne Prop
  | AtMostOne Prop
  | None Prop
  | All Prop
  | Exactly Int Prop
  -- | Particular Which Prop -- not sure if this is necessary, but it makes the wording interesting
  | NumericalRelationship NumericalRelationship

data NumericalRelationship
  = Equals [Quantity] -- two or more
  | AllUnequal [Quantity] -- two or more
  | LT Quantity Quantity
  | LTE Quantity Quantity
  | GT Quantity Quantity
  | GTE Quantity Quantity

data Quantity
  = RawNumber Int
  | Sum Prop
  | Count Prop -- CountTrue just counts all of the cards
  | RankOf PositionProp
  | PositionOf SpecificCard

data Prop
  = Color Color
  | Suit Suit
  | Rank Rank -- might want to also make a suit+rank combo constructor, as that might actually be pretty easy
  | Face
  | And Prop Prop
  | Or Prop Prop
  | Not Prop
  | Implies Prop Prop
  | Xor Prop Prop
  | True
  | False
  | LT Rank
  | LTE Rank
  | GT Rank
  | GTE Rank
  | UniqueProp UniqueProp

data PositionProp =
  = First -- need to do some finagling to make sure that unique props are worded differently than non-unique props
  | Last
  | Position Int

data SpecificCard = SpecificCard Rank Suit

data Color
  = Red
  | Black

data Suit
  = Heart
  | Club
  | Suit
  | Spade
*/

module.exports =
  something: 5
  runParser: run-parser
  pure: pure
  o: o
  miniParse: mini-parse
  nop: nop
  onRuleInputChange: on-rule-input-change
  ruleG: rule-g
  fold1: fold1
  optionallyPlural: optionally-plural
  map: map
  rankG: rank-g
  runDebug: run-debug
  runPrint: run-print
  colorG: color-g
  propertyG: property-g
  colorConstructor: color-constructor
  deconstructColor: deconstruct-color
  any: any
