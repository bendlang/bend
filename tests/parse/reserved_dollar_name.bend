# audit 007: '$' is not name material: a user name cannot carry it, so
# a user def can never collide with a machine-minted name.
# ported from bend3
law foo:
  Unit

def foo$bar(): Unit{}

law main:
  Unit

def main(): foo$bar

#|SOME PROOFS FAIL
#|Error:
#|- expected : '('
#|- observed : '$'
#|Location:
#|6 | 
#|7>| def foo$bar(): Unit{}
#|  |        ^
#|8 |
#|exit 1
