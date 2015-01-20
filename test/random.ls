require! assert
r = require \../js-src/random

describe 'zeroes all the way' -> ``it``
  .. 'should give me the all red rule' ->
    zero-rand = { next: -> 0 }
    rule = r.random-rule(0, zero-rand)
    assert.deepEqual rule, {all:{property:{isColor:{color:{red:{}}}}}}
