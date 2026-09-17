# descent on a 2-deep literal pattern: the self-call on the ONE-LAYER
# rebuilt argument (S{p} off a matched S{S{p}}) is accepted -- the
# rebuilt cell is a strict subterm of the refined column.
# ported from bend3: bare ctors S/Z over the test's own N, len
# answers the base Nat
import Base

type N is Data:
  Z{}
  S{p: N}

law parity:
  for n: N
  N

def parity(n):
  match n:
    case Z{}:
      Z{}
    case S{Z{}}:
      S{Z{}}
    case S{S{p}}:
      parity(S{p})

law len:
  for n: N
  Nat

def len(n):
  match n:
    case Z{}:
      0n
    case S{p}:
      1n+ len(p)

law main.out:
  Nat

def main.out(): len(parity(S{S{S{S{S{Z{}}}}}}))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|1n
