
# complexity 0 means only simple rules
# complexity 1 means 'and' is allowed once
# complexity 2 means 'and' is allowed thrice
# complexity 3 means 'and' is allowed seven times
# complexity is an upper-bound on the amount of recursion that is
#   allowed in the rules, and so grows exponentially
# rand is an object with a next(int) method, which picks
# a random integer between 0 and one less than the given value.
# Unit tests can pass in a fixed random generator for
# consistency, but they will probably be fragile anyway.
random-rule = (complexity, rand) ->
  if complexity > 0 && rand.next(2) == 0
    { and: { left: random-rule(complexity - 1, rand), right: random-rule(complexity - 1, rand) } }
  else if rand.next(2) == 0
    { all: { property: random-property(complexity, rand) } }
  else
    { atLeastOne: { property: random-property(complexity, rand) } }

random-property = (complexity, rand) ->
  which = rand.next(3)
  if which == 0
    { isColor: { color: random-color(complexity, rand) } }
  else if which == 1
    { isRank: { rank: random-rank(complexity, rand) } }
  else
    { hasSuit: { suit: random-suit(complexity, rand) } }

random-color = (complexity, rand) ->
  if rand.next(2) == 0
    { red: {} }
  else
    { black: {} }

random-suit = (complexity, rand) ->
  throw new Error("random-suit not implemented")

random-rank = (complexity, rand) ->
  throw new Error("random-rank not implemented")

module.exports = {
  randomRule: random-rule
}
