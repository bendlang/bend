# the do-head opens its type arguments with a GLUED angle group:
# `do M<A>:` is the form (bend3 pinned the <> sugar over an
# application head; bend's grammar is the angle group itself).
# ported from bend3
type Nn3 is Data:
  Zz3{}
  Ss3{p: Nn3}

type Id_<-A: Data> is Data:
  MkId{v: A}

law Id_.pure:
  for -A: Data
  for  v: A
  Id_<A>

def Id_.pure(A, v):
  MkId{v}

law Id_.bind:
  for -A: Data
  for -B: Data
  for  m: Id_<A>
  for  f: A -> Id_<B>
  Id_<B>

def Id_.bind(A, B, m, f):
  match m:
    case MkId{v}:
      f(v)

law run:
  for m: Id_<Nn3>
  Nn3

def run(m):
  match m:
    case MkId{v}:
      v

law main:
  Nn3

def main():
  run(do Id_<Nn3>:
        x : Nn3 <- MkId{Ss3{Zz3{}}}
        return Ss3{x})

#|Ss3{Ss3{Zz3{}}}
