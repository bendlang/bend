# audit: ctor rows are shape-delimited and layout-free: inline rows after
# the colon parse the same as newline-separated ones.
# ported from bend3: bare unique ctors, U32.add for +
type Nn is Data: Zz{} Ss{p: Nn}

law nn_len:
  for n: Nn
  Nn

def nn_len(n):
  match n:
    case Zz{}:
      Zz{}
    case Ss{p}:
      Ss{nn_len(p)}

law main:
  Nn

def main():
  nn_len(Ss{Ss{Ss{Zz{}}}})

#|Ss{Ss{Ss{Zz{}}}}
