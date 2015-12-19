{
  all,
  any
} = require \prelude-ls

evaluate-top = (rule, cards) ->
  if rule.and != void
    evaluate-top(rule.and.left,cards) && evaluate-top(rule.and.right,cards)
  else if rule.all != void
    evaluator = (card) -> evaluate-property(rule.all.property, card)
    all(evaluator, cards)
  else if rule.at-least-one != void
    evaluator = (card) -> evaluate-property(rule.atLeastOne.property, card)
    any(evaluator, cards)
  else
    throw new Error("Don't know how to process rule.")

evaluate-property = (property, card) ->
  if property.has-suit != void
    evaluate-suit(property.has-suit.suit, card)
  else if property.is-rank != void
    evaluate-rank(property.is-rank.rank, card)
  else if property.is-color != void
    result = evaluate-color(property.is-color.color, card)
    result
  else
    throw new Error("Don't understand that property.")

evaluate-suit = (suit, card) ->
  throw new Error("Suit not implemented")

evaluate-rank = (rank, card) -> throw new Error("Rank not implemented")

evaluate-color = (color, card) ->
  suit = card.slice(-1)[0]
  if color.red != void
    suit == 'H' || suit == 'D'
  else if color.black != void
    suit == 'C' || suit == 'S'
  else
    throw new Error("Don't understand color.")

module.exports = {
  evaluateTop: evaluate-top
}
