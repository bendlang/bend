# a nat literal in a pattern checks the constructors it expands to: past
# NAT_LITERAL_MAX it parses as U32.to_nat(n), and that pattern needs the same
# Zero and Succ lookup the braced form gets. Without it a Zero carrying a
# field matches as if it were nullary, and the field becomes a binder on the
# branch.
type U is Data:
  Un{}

type N is Data:
  Zero{w: U}
  Succ{p: N}

law g:
  for b: N
  U

def g(b):
  match b:
    case 257n:
      Un{}
    case Succ{p}:
      g(p)

law main:
  U

def main(): g(Zero{Un{}})

#|Error:
#|- message  : a Zero pattern with 1 field
#|Location:
#|18 |   match b:
#|19>|     case 257n:
#|20 |       Un{}
#|exit 1
