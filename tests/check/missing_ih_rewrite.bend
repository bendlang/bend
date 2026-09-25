# a failed proof is an ORDINARY local type error: the arm that forgot
# its IH rewrite reports the two stuck sides at the {==}, with context.
# ported from bend3
type Nh is Data:
  Zh{}
  Sh{p: Nh}

law add:
  for a: Nh
  for b: Nh
  Nh

def add(a, b):
  match a:
    case Zh{}:
      b
    case Sh{p}:
      Sh{add(p, b)}

law add_zero:
  for a: Nh
  {add(a, Zh{}) == a : Nh}

def add_zero(a):
  match a:
    case Zh{}:
      {==}
    case Sh{p}:
      {==}

#|Error:
#|- expected : Sh{add(p, Zh{})}
#|- observed : Sh{p}
#|Context:
#|- p : Nh
#|Location: add_zero
#|28 |     case Sh{p}:
#|29>|       {==}
#|   |       ^^^^
#|30 |
#|exit 1
