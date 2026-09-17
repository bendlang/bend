# bend3's bystander pin: a split must never normalize a hypothesis's
# type, and the counter that proved it is gone (no --stats). The
# program carries whole -- the heavy build(3000n) hypothesis stands by
# and the match checks and answers on every lane (build's countdown
# rides base Nat)
import Base

type N9 is Data:
  Z9{}
  S9{p: N9}

law build:
  for n: Nat
  List<&2, U32>

def build(n):
  match n:
    case Zero{}:
      Nil{}
    case Succ{k}:
      0 <> build(k)

law isz:
  for n: N9
  N9

def isz(n):
  match n:
    case Z9{}:
      Z9{}
    case S9{p}:
      S9{p}

law f.go:
  for w: N9
  N9

def f.go(w):
  match w:
    case Z9{}:
      Z9{}
    case S9{p}:
      Z9{}

law f:
  for n: N9
  for h: {build(3000n) == Nil{} : List<&2, U32>}
  N9

def f(n, h):
  f.go(isz(n))

law main:
  N9

def main():
  Z9{}

#|Z9{}
