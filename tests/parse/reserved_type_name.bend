# error census: reserved words are rejected as type names.
# ported from bend3
type match:
  Kk10{}

#|Error:
#|- expected : a name (got the keyword 'match')
#|- observed : 'match'
#|Location:
#|2 | # ported from bend3
#|3>| type match:
#|  |      ^^^^^
#|4 |   Kk10{}
#|exit 1
