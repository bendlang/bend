# minted names must render on every backend: the computed-scrutinee
# match (checker-minted split aux), the dynamic apply, and a shared
# word all compile natively
# ported from bend3: the &n share becomes a +let
import Base

type Shape is Data:
  Cir{r: U32}
  Sqr{q: U32}

law pick.go:
  for s: Shape
  U32

def pick.go(s):
  match s:
    case Cir{r}:
      r
    case Sqr{q}:
      q

law pick:
  for k: U32
  U32

def pick(k):
  pick.go({Sqr{U32.add(k, 1)} : Shape})

law run:
  (U32 -> U32) -> U32

def run():
  f => f(3)

law main.out:
  U32

def main.out():
  +n = {pick(10) : U32}
  U32.add(run(x => U32.add(x, n)), n)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|25
