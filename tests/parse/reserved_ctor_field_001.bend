# red-team pin: reserved keywords are rejected as ctor FIELD names (a
# field is a binder).
# ported from bend3
type Kk9 is Data:
  Mk9{match: Unit}

law main:
  Unit

def main(): Unit{}

#|Error:
#|- expected : a name (got the keyword 'match')
#|- observed : ':'
#|Location:
#|4 | type Kk9 is Data:
#|5>|   Mk9{match: Unit}
#|6 |
#|exit 1
