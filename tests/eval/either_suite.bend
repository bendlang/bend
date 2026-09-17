# Either coverage: A | B parses to Either<A, B>, & and | share one
# precedence and right-nest in bend -- (U32 & U32) | U32 needs its
# parens -- a type argument parenthesizes: id((U32 | U32), ..), L/R
# build, matches dispatch both arms, and an R-biased kit chains.
# ported from bend3: Either.L/R become Inl/Inr, the bend3-base kit
# (map/bind/or/pure) becomes local defs over U32, result 35 (bend3's
# golden) shown as a Nat
import Base

law id:
  for -A: Type
  for  x: A
  A

def id(A, x):
  x

law side:
  for e: U32 | U32
  U32

def side(e):
  match e:
    case Inl{value}:
      value
    case Inr{value}:
      U32.add(value, 1)

law both:
  for e: (U32 & U32) | U32
  U32

def both(e):
  match e:
    case Inl{value}:
      (a, b) = value
      U32.add(a, b)
    case Inr{value}:
      value

law emap:
  for f: @x:U32 -> U32
  for e: U32 | U32
  U32 | U32

def emap(f, e):
  match e:
    case Inl{value}:
      Inl{value}
    case Inr{value}:
      Inr{f(value)}

law ebind:
  for e: U32 | U32
  for f: @x:U32 -> (U32 | U32)
  U32 | U32

def ebind(e, f):
  match e:
    case Inl{value}:
      Inl{value}
    case Inr{value}:
      f(value)

law eor:
  for d: U32
  for e: U32 | U32
  U32

def eor(d, e):
  match e:
    case Inl{value}:
      d
    case Inr{value}:
      value

law inc:
  for x: U32
  U32 | U32

def inc(x):
  Inr{U32.add(x, 1)}

law chain:
  for e: U32 | U32
  U32

def chain(e):
  eor(0, ebind(emap(x => U32.mul(x, 2), e), inc))

law main.out:
  Nat

def main.out():
  U32.to_nat(U32.add(U32.add(U32.add(side(Inr{4}), both(Inl{(2, 3)})), side(id((U32 | U32), Inl{10}))), chain(Inr{7})))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|35n
