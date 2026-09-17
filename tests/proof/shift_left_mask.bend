# the left-shift roster, on bend's own law (the ruled port of bend3's
# 5-bit count mask kit: bend's U32.shln takes a Nat count and shifts
# OUT past the width -- no mask exists, run_word_shifts verified it,
# and here it is pinned as theorems): the one-step hom is definitional
# (shln(1) IS shl), composition holds at ANY counts by base's
# U32.shln_add -- the very law bend3's mask refuted at 16+16 -- the
# open-count low bit is even (base's U32.shl_even), and the mask edges
# invert: 32 and 33 shift to zero, proved closed by plain reduction.
# ported from bend3: main carries run_word_shifts' battery -- the five
# in-range pins agree across dialects, the three mask-edge pins re-pin
# to bend's shift-out (1<<32 = 0 where bend3's mask said 1) -- and the
# golden 8 carries; bend3's masked main (65) has no bend value
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

law U32.shln_add:
  for k: Nat
  for m: Nat
  for a: U32
  {U32.shln(U32.shln(a, m), k) == U32.shln(a, Nat.add(k, m)) : U32}

def U32.shln_add(k, m, a):
  match k:
    case 0n:
      {==}
    case 1n+q:
      %U32.shln_add(q, m, a) : {U32.shl(U32.shln(U32.shln(a, m), q)) == U32.shl(_) : U32}
      {==}

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

law shl_hom_one:
  for a: U32
  {U32.shln(a, 1n) == U32.shl(a) : U32}

def shl_hom_one(a):
  {==}

law shln_compose:
  for a: U32
  {U32.shln(U32.shln(a, 16n), 16n) == U32.shln(a, 32n) : U32}

def shln_compose(a):
  U32.shln_add(16n, 16n, a)

law shln_low_bit:
  for a: U32
  {Nat.even(U32.to_nat(U32.shln(a, 1n))) == True{} : Bool}

def shln_low_bit(a):
  U32.shl_even(a)

law shl32_gone:
  {U32.shln(5, 32n) == 0 : U32}

def shl32_gone():
  {==}

law shl33_gone:
  {U32.shln(3, 33n) == 0 : U32}

def shl33_gone():
  {==}

law bu:
  for b: Bool
  U32

def bu(b):
  match b:
    case False{}:
      0
    case True{}:
      1

law main.out:
  U32

def main.out():
  b0 = bu(U32.is_eq((1 << 31n : U32), 2147483648))
  b1 = bu(U32.is_eq((1 << 32n : U32), 0))
  b2 = bu(U32.is_eq((3 << 31n : U32), 2147483648))
  b3 = bu(U32.is_eq((2147483648 >> 31n : U32), 1))
  b4 = bu(U32.is_eq((2147483648 >> 32n : U32), 0))
  b5 = bu(U32.is_eq((5 >> 33n : U32), 0))
  b6 = bu(U32.is_eq((4294967295 << 28n : U32), 4026531840))
  b7 = bu(U32.is_eq((1 << 0n : U32), 1))
  (b0 + b1 + b2 + b3 + b4 + b5 + b6 + b7 : U32)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|8
