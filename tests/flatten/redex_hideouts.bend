# bend3's prep_unfold redex hideouts (a Lone let's literal lam, and
# statements commuting through value positions); bend has no such
# pass and the shapes simply evaluate -- the computed scrutinee
# routes through a worker def (a computed match is a banned form),
# the lam let moves under the arm (a match heads a def body),
# and the value carries: 22
import Base

type B8r is Data:
  B8r{a: U32}

law use:
  for f: U32 -> U32
  U32

def use(f):
  y = f(3)
  (y + 1 : U32)

law mk:
  for k: U32
  B8r

def mk(k):
  B8r{use(x => (x * 2 + k : U32))}

law main.out:
  Nat

law main.rd:
  for bx: B8r
  Nat

def main.rd(bx):
  match bx:
    case B8r{a}:
      h = {x => (x + 1 : U32) : U32 -> U32}
      U32.to_nat((h(a) + use(x => (x + 10 : U32)) : U32))

def main.out():
  main.rd(mk(0))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|22n
