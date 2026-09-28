# error census: reserved words are rejected as assert names.
# ported from bend3
law match:
  Unit

#|SOME PROOFS FAIL
#|Error:
#|- expected : a name (got the keyword 'match')
#|- observed : 'match'
#|Location:
#|2 | # ported from bend3
#|3>| law match:
#|  |     ^^^^^
#|4 |   Unit
#|exit 1
