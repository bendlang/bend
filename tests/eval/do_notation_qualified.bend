# a do-block's monad head may be a QUALIFIED (dotted) name: the desugar
# glues .bind/.pure onto the whole head (do M.Id<..>: -> M.Id.bind).
# ported from bend3: M.Id(A) becomes M.Id<A>, the bind spells its
# per-line type, result 42 shown as a Nat
import Base

type M.Id<-A: Type> is Type:
  MkMId{v: A}

law M.Id.pure:
  for -A: Type
  for  v: A
  M.Id<A>

def M.Id.pure(A, v):
  MkMId{v}

law M.Id.bind:
  for -A: Type
  for -B: Type
  for  m: M.Id<A>
  for  f: @x:A -> M.Id<B>
  M.Id<B>

def M.Id.bind(A, B, m, f):
  match m:
    case MkMId{v}:
      f(v)

law run:
  for m: M.Id<U32>
  U32

def run(m):
  match m:
    case MkMId{v}:
      v

law main.out:
  Nat

def main.out():
  U32.to_nat(run(do M.Id<U32>:
    x : U32 <- {MkMId{40} : M.Id<U32>}
    return U32.add(x, 2)))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|42n
