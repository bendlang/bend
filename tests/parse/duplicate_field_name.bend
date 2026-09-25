# a field declared twice within one constructor is a parse error: the
# theory binds fields by position, but the JS lane keys them by name,
# so a repeated name collapsed two fields into one (#899)
type Aa is Data:
  Kk{x: U32, x: U32}

def main() -> U32:
  match Kk{1, 2}:
    case Kk{a, b}: a

#|Error:
#|- expected : a fresh field name (duplicate declaration: x)
#|- observed : 'x'
#|Location:
#|4 | type Aa is Data:
#|5>|   Kk{x: U32, x: U32}
#|  |              ^
#|6 |
#|exit 1
