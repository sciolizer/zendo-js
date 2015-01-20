{
  fold1,
  map
} = require \prelude-ls
b = require \boomerang-grammar

o = b.either

single = (f) -> (item) -> [f(item)]

optionally-plural = (word) ->
  plural = if word == \six then \sixes else word + \s
  article = if word == \ace then \an else \a
  deconstruct-word = (thing) -> if thing and thing[word] then [] else void
  [b.pure(-> { "#word": {} }, deconstruct-word), plural `o` [article, word]]

rule =
  and: { left: \rule, right: \rule }
  atLeastOne: { property: \property }
  all: { property: \property }

#none = <[none of the numbers are]> `o` <[no number is]>
#sum = ['the', 'sum' `o` 'total', b.optional(<[of the numbers]>), 'is']
#smallest = ['the', ('smallest' `o` 'minimum') `o` 'least', b.optional('number'), 'is']
#largest = ['the', ('largest' `o` 'biggest') `o` 'maximum', b.optional('number'), 'is']
#first = ['the', 'first', b.optional('number'), 'is']
#last = ['the', 'last', b.optional('number'), 'is']
#of-numbers = <[of numbers]>

property =
  isColor: { color: \color }
  hasSuit: { suit: \suit }
  isRank: { rank: \rank }
  isFace: {}

rank-g = b.any(map optionally-plural, <[ace two three four five seven eight nine ten jack queen king]>)

suit-g = b.any(map optionally-plural, <[heart club diamond spade]>)

deconstruct-red = (color) -> if color and color.red then [] else void

deconstruct-black = (color) -> if color and color.black then [] else void

red-constructor = ->
  { red: {} }

black-constructor = ->
  { black: {} }

color-g = [b.pure(-> { red: {} }, deconstruct-red), \red] `o` [b.pure(-> { black: {} }, deconstruct-black), \black]

deconstruct-color = (property) ->
  if property && property.isColor && property.isColor.color
    [property.isColor.color]

color-constructor = (color) ->
  { isColor: { color } }

property-g = b.any do
  * [b.pure(color-constructor, deconstruct-color), color-g]
    [b.pure((suit) -> { hasSuit: { suit } }, single((?.hasSuit?.suit))), suit-g]
    [b.pure((rank) -> { isRank: { rank } }, single((?.isRank?.rank))), rank-g]

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
each-and-every-g = ['each', b.optional(<[and every]>)] `o` 'every'
all-g = [b.pure(all-construct, deconstruct-all), [each-and-every-g, 'card', 'is'] `o` <[all cards are]>, property-g]
at-least-one-g = [b.pure((property) -> { atLeastOne: { property } }, single((?.atLeastOne?.property))), [b.optional(['at', 'least']), 'one', <[of the cards]> `o` 'card', 'is'] `o` ['a' `o` 'any', 'card', 'is'], property-g]

and-deconstructor = (rule) ->
  left = rule?.and?.left
  right = rule?.and?.right
  if left != void && right != void
    [left, right]

quantifier-g = b.any [all-g, at-least-one-g]

and-g = [b.pure((left, right) -> { and: { left, right } }, and-deconstructor), quantifier-g, \and, b.recursive(-> rule-g)]

rule-g = [b.any [quantifier-g, and-g], b.eof]

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


  all of the red cards are to the left of all of the black cards
  forall red. forall black. red before black
  all cards are of different rank
*/

module.exports =
  colorConstructor: color-constructor
  colorG: color-g
  deconstructColor: deconstruct-color
  optionallyPlural: optionally-plural
  propertyG: property-g
  rankG: rank-g
  ruleG: rule-g
