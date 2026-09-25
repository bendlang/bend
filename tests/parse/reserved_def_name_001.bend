# audit: reserved words are rejected as definition names.
# ported from bend3
def match(x):
  x

#|Error:
#|- expected : a name (got the keyword 'match')
#|- observed : 'match'
#|Location:
#|2 | # ported from bend3
#|3>| def match(x):
#|  |     ^^^^^
#|4 |   x
#|exit 1
