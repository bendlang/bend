# audit: reserved words are rejected as top-level def names (zero-arg
# form).
# ported from bend3
def match(): Unit{}

#|Error:
#|- expected : a name (got the keyword 'match')
#|- observed : 'match'
#|Location:
#|3 | # ported from bend3
#|4>| def match(): Unit{}
#|  |     ^^^^^
#|5 |
#|exit 1
