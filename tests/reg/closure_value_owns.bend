# regression witness (b3f448e): a def used as a closure VALUE owns its
# arguments -- lending once read borrow rows off direct call sites
# alone, so every Clo.apply entry leaked the argument's heap (47 MB
# per million applications, right answer printed). The rss pin below
# is the tripwire; no interpreter block: a million-step loop is the
# backends' job.
import Base

type Tr is Data:
  L{v: U32}
  N{a: Tr, b: Tr}

law build:
  for +d: Nat
  for +x: U32
  Tr

def build(d, x):
  match d:
    case 0n:
      L{x}
    case 1n+p:
      N{build(p, x), build(p, U32.add(x, 1))}

law pick:
  for t: Tr
  U32

def pick(t):
  match t:
    case L{v}:
      v
    case N{a, b}:
      U32.add(pick(a), pick(b))

law hof:
  for f: Tr -> U32
  for t: Tr
  U32

def hof(f, t):
  f(t)

law mint:
  for +t: Tr
  U32 -> U32

def mint(t):
  x => U32.add(pick(t), x)

law loop:
  for n   : Nat
  for +t  : Tr
  for acc : U32
  U32

def loop(n, t, acc):
  match n:
    case 0n:
      acc
    case 1n+q:
      loop(q, t, U32.add(acc, U32.add(hof(pick, t), mint(t)(1))))

law main.out:
  U32

def main.out():
  loop(U32.to_nat(1000000), build(3n, 1), 0)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|41000000
