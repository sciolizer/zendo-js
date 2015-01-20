require! assert
ev = require \../js-src/evaluate

describe \all-red -> ``it``
  rule = {all:{property:{isColor:{color:{red:{}}}}}}
  .. 'should recognize the empty koan as all red' ->
    result = ev.evaluate-top rule, []
    assert.equal result, true
  .. 'should recognize a 2 of hearts as red' ->
    result = ev.evaluate-top rule, ["2H"]
    assert.equal result, true
  .. 'should recognize a heart and diamond as red' ->
    result = ev.evaluate-top rule, ["2H", "AD"]
    assert.equal result, true
  .. 'should reject a single black card' ->
    result = ev.evaluate-top rule, ["KC"]
    assert.equal result, false
  .. 'should reject if the first is black' ->
    result = ev.evaluate-top rule, ["KS", "AH"]
    assert.equal result, false
  .. 'should reject if the second is black' ->
    result = ev.evaluate-top rule, ["AH", "KS"]
    assert.equal result, false

