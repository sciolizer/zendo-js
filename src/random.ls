
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
  if rand == void
    rand = { next: (cap) -> Math.floor(Math.random() * cap) }
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
  suit = rand.next(4)
  if suit == 0
    { club: {} }
  else if suit == 1
    { diamond: {} }
  else if suit == 2
    { heart: {} }
  else if suit == 3
    { spade: {} }
  else
    throw new Error("Rand not in range: " + suit)

random-rank = (complexity, rand) ->
  rank = rand.next(13) + 1
  if rank == 1
    { ace: {} }
  else if rank == 2
    { two: {} }
  else if rank == 3
    { three: {} }
  else if rank == 4
    { four: {} }
  else if rank == 5
    { five: {} }
  else if rank == 6
    { six: {} }
  else if rank == 7
    { seven: {} }
  else if rank == 8
    { eight: {} }
  else if rank == 9
    { nine: {} }
  else if rank == 10
    { ten: {} }
  else if rank == 11
    { jack: {} }
  else if rank == 12
    { queen: {} }
  else if rank == 13
    { king: {} }
  else
    throw new Error("rank out of range: " + rank)

module.exports = {
  randomRule: random-rule
}
