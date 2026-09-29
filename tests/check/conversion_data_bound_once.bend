# a value bound again is not walked again: allone's tail is already in
# normal form when the next step binds it, and going through val once
# per step made a walk of n cells cost n². idl forces the conversion
# (the stated type and the proof's differ), which is what makes the
# kernel normalize the list at all; 2048 cells is past the 850 where
# --verdict used to run out of fuel (#1071's shape, on closed data)
import Base

def and_both(+p: Bool, +q: Bool,
  +a: {p == True{} : Bool}, +b: {q == True{} : Bool})
  -> {Bool.and(p, q) == True{} : Bool}:
  match p:
    case True{}:
      b
    case False{}:
      a

def ones(+k: Nat) -> List<&2, U32>:
  match k:
    case 0n:
      Nil{}
    case 1n+j:
      Con{1, ones(j)}

def allone(+xs: List<&2, U32>) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case Con{h, t}:
      Bool.and(U32.is_eq(h, 1), allone(t))

law ones_ok:
  for +k: Nat
  {allone(ones(k)) == True{} : Bool}

def ones_ok(k):
  match k:
    case 0n:
      {==}
    case 1n+j:
      and_both(U32.is_eq(1, 1), allone(ones(j)), {==}, ones_ok(j))

def idl(xs: List<&2, U32>) -> List<&2, U32>:
  xs

def all_ones_2048() -> {allone(idl(ones(2048n))) == True{} : Bool}:
  ones_ok(2048n)

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
