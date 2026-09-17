# bend3 pinned the embedded GPU program's reachability by csrc marks;
# bend's emitter has its own shapes, so the half that carries is the
# mark's semantics: a host-computed argument feeds a marked root and
# the value is the plain call's, on every lane (the countdown rides
# Nat: no numeric patterns)
import Base

law cpu_only:
  for x: Nat
  Nat

def cpu_only(x):
  Nat.mul(x, 2n)

law gpu_only:
  for x: Nat
  Nat

def gpu_only(x):
  match x:
    case Zero{}:
      7n
    case Succ{p}:
      Succ{gpu_only(p)}

law main.out:
  Nat

def main.out():
  x = cpu_only(4n)
  gpu_only!(x)

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|15n
