# a TWO-column match in a proof: the dependent goal refines across both
# scrutinees at once (four leaves, each closed by conversion).
# ported from bend3: a local Bool keeps its own namespace, ctors bare
type Bit is Data:
  T{}
  F{}

law and2:
  for a: Bit
  for b: Bit
  Bit

def and2(a, b):
  match a, b:
    case T{}, T{}:
      T{}
    case T{}, F{}:
      F{}
    case F{}, T{}:
      F{}
    case F{}, F{}:
      F{}

law and_comm:
  for a: Bit
  for b: Bit
  {and2(a, b) == and2(b, a) : Bit}

def and_comm(a, b):
  match a, b:
    case T{}, T{}:
      {==}
    case T{}, F{}:
      {==}
    case F{}, T{}:
      {==}
    case F{}, F{}:
      {==}

law main:
  {and2(T{}, F{}) == and2(F{}, T{}) : Bit}

def main(): and_comm(T{}, F{})

#|{==}
