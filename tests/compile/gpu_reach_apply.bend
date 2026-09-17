# bend3 pinned the GPU program's dynamic-apply closure set by csrc
# marks; bend's emitter has its own shapes, so the semantic half
# carries: a marked root taking a host-built partial application
# answers the plain call's value on every lane
import Base

law cpu_only:
  for x: U32
  U32

def cpu_only(x):
  (x + 40 : U32)

law run:
  for f: U32 -> U32
  for x: U32
  U32

def run(f, x):
  f(x)

law add2:
  for a: U32
  for b: U32
  U32

def add2(a, b):
  (a + b : U32)

law main.out:
  Nat

def main.out():
  x = cpu_only(0)
  U32.to_nat(run!(add2(2), x))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|42n
