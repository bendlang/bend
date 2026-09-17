# nested pattern: Sc{Sc{p}} (all linear: no arm uses a value twice)
# ported from bend3: local Nat-like type, the builder walks a Nat
import Base

type Nt is Data:
  Zr{}
  Sc{p: Nt}

law half:
  for n: Nt
  U32

def half(n):
  match n:
    case Zr{}:
      0
    case Sc{Zr{}}:
      0
    case Sc{Sc{p}}:
      U32.add(1, half(p))

law mk:
  for m: Nat
  Nt

def mk(m):
  match m:
    case 0n:
      Zr{}
    case 1n+p:
      Sc{mk(p)}

law main.out:
  U32

def main.out():
  half(mk(9n))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|4
