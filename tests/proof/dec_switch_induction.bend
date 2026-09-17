# numeric induction end to end, respelled on Nat (the ruled port of
# bend3's U32 dec-switch: number patterns became U32.to_nat + Nat
# recursion): zero_zero closes by the IH alone, id_id and two_id ride
# one cong per arm, id_id2 is the nested-peel spelling as a ladder, and
# the U32 faces carry the runtime -- idu(1 + 4294967295) pins that the
# machine word still wraps under the face while the Nat proofs hold.
# ported from bend3: main keeps the golden 51
import Base

law zeron:
  for n: Nat
  Nat

def zeron(n):
  match n:
    case 0n:
      0n
    case 1n+p:
      zeron(p)

law zero_zero:
  for x: Nat
  {zeron(x) == 0n : Nat}

def zero_zero(x):
  match x:
    case 0n:
      {==}
    case 1n+p:
      zero_zero(p)

law idn:
  for n: Nat
  Nat

def idn(n):
  match n:
    case 0n:
      0n
    case 1n+p:
      1n+idn(p)

law id_id:
  for x: Nat
  {idn(x) == x : Nat}

def id_id(x):
  match x:
    case 0n:
      {==}
    case 1n+p:
      Equal.cong(Nat, Nat, y => 1n+y, idn(p), p, id_id(p))

law twon:
  for n: Nat
  Nat

def twon(n):
  match n:
    case 0n:
      0n
    case 1n:
      1n
    case 2n+p:
      2n+twon(p)

law two_id:
  for x: Nat
  {twon(x) == x : Nat}

def two_id(x):
  match x:
    case 0n:
      {==}
    case 1n:
      {==}
    case 2n+p:
      Equal.cong(Nat, Nat, y => 2n+y, twon(p), p, two_id(p))

law id_id2:
  for x: Nat
  {idn(x) == x : Nat}

def id_id2(x):
  match x:
    case 0n:
      {==}
    case 1n:
      {==}
    case 2n+q:
      Equal.cong(Nat, Nat, y => 2n+y, idn(q), q, id_id(q))

law zerou:
  for x: U32
  U32

def zerou(x):
  U32.from_nat(zeron(U32.to_nat(x)))

law idu:
  for x: U32
  U32

def idu(x):
  U32.from_nat(idn(U32.to_nat(x)))

law twou:
  for x: U32
  U32

def twou(x):
  U32.from_nat(twon(U32.to_nat(x)))

law main.out:
  U32

def main.out():
  (zerou(100) + idu(41) + twou(10) + idu((1 + 4294967295 : U32)) : U32)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|51
