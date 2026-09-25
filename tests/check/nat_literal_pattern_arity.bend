# a nat literal in a pattern is checked like any constructor. parse_patt
# turned a literal above NAT_LITERAL_MAX (parsed as U32.to_nat(n)) into
# a Succ/Zero pattern chain of its own, skipping the constructor case, so
# 257n passed where the hand-written Zero{} is refused at its arity. the
# literal now expands to constructor terms and takes the same path
type U is Data:
  Un{}
type N is Data:
  Zero{w: U}
  Succ{p: N}

def f(b: N) -> U:
  match b:
    case 257n:
      Un{}
    case Succ{p}:
      f(p)

#|Error:
#|- message  : a Zero pattern with 1 field
#|Location:
#|13 |   match b:
#|14>|     case 257n:
#|   |          ^^^^
#|15 |       Un{}
#|exit 1
