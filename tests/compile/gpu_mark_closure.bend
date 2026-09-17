# bend3 pinned the marked partial call's runtime closure by csrc marks
# (G_WALK aliases); bend's emitter has its own closure shapes, so the
# semantic half carries: a marked partial named call, ascribed and
# passed as a closure, answers the plain chain's value (the countdown
# rides Nat)
import Base

law walk:
  for d: Nat
  for x: U32
  U32

def walk(d, x):
  match d:
    case Zero{}:
      x
    case Succ{p}:
      walk(p, (x + 1 : U32))

law use:
  for f: U32 -> U32
  for x: U32
  U32

def use(f, x):
  f(x)

law main.out:
  Nat

def main.out():
  f = {walk!(4n) : U32 -> U32}
  U32.to_nat(use(f, 3))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|7n
