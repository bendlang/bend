# recursion under nested split auxes with a contracted default binder
# ported from bend3: counters walk Nats, the shared peel becomes a
# +scrutinee
import Base

type Bl is Data:
  Tt{}
  Ff{}

law notb:
  for a: Bl
  Bl

def notb(a):
  match a:
    case Tt{}:
      Ff{}
    case Ff{}:
      Tt{}

law par:
  for a: Nat
  Bl

def par(a):
  match a:
    case 0n:
      Tt{}
    case 1n+n2:
      notb(par(n2))

law run.sel:
  for r  : U32
  for p1 : Bl
  for p2 : Bl
  U32

def run.sel(r, p1, p2):
  match p1:
    case Tt{}:
      match p2:
        case Tt{}:
          U32.add(1, r)
        case Ff{}:
          0
    case Ff{}:
      r

law run:
  for +n: Nat
  U32

def run(n):
  match n:
    case 0n:
      0
    case 1n+n2:
      run.sel(run(n2), par(n2), par(n2))

law main.out:
  U32

def main.out():
  U32.add(run(2n), U32.add(run(1n), run(3n)))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|4
