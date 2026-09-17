# the wrap-crossing exemplar, on Word directly (the ruled port of
# bend3's hom route: no roster, no unary crossing): doubling is the
# machine shift (U32.shl IS 2x mod 2^32), and par2(dbl(x)) = 0 for ALL
# x -- past 2^31 included -- because a left shift lands a zero low bit:
# base's U32.shl_even, whose truth is 2^32 being even, a fact no
# induction below MAX reaches. The proof is strict:
# par2's decision is factored into par2.go (a computed match never
# specializes), so one cong over the even verdict closes the goal.
# ported from bend3: main keeps the golden 420
import Base

law Nat.even:
  for m: Nat
  Bool

def Nat.even(m):
  match m:
    case 0n:
      True{}
    case 1n:
      False{}
    case 2n+r:
      Nat.even(r)

law Nat.even_double:
  for m: Nat
  {Nat.even(Nat.double(m)) == True{} : Bool}

def Nat.even_double(m):
  match m:
    case 0n:
      {==}
    case 1n+q:
      Nat.even_double(q)

law U32.shl_even.go:
  for w: Word(32n)
  {Nat.even(Word.to_nat(32n, Word.shl(32n, w))) == True{} : Bool}

def U32.shl_even.go(w):
  match w:
    case WCon{b, t}:
      Nat.even_double(Word.to_nat(31n, Word.shl.put(31n, b, t)))

law U32.shl_even:
  for a: U32
  {Nat.even(U32.to_nat(U32.shl(a))) == True{} : Bool}

def U32.shl_even(a):
  match a:
    case U32{w}:
      U32.shl_even.go(w)

law dbl:
  for x: U32
  U32

def dbl(x):
  U32.shl(x)

law par2.go:
  for b: Bool
  U32

def par2.go(b):
  match b:
    case True{}:
      0
    case False{}:
      1

law par2:
  for x: U32
  U32

def par2(x):
  par2.go(Nat.even(U32.to_nat(x)))

law par2_dbl:
  for x: U32
  {par2(dbl(x)) == 0 : U32}

def par2_dbl(x):
  Equal.cong(Bool, U32, b => par2.go(b), Nat.even(U32.to_nat(U32.shl(x))), True{}, U32.shl_even(x))

law main.out:
  U32

def main.out():
  (dbl(21) * 10 + par2(dbl(21)) : U32)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|420
