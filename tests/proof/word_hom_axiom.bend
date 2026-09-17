# bend3's blessed U32 reasoning route rode a whitelisted hom axiom into
# Word; bend has no roster to bless -- U32 IS Word(32n), so the same
# machine-word statement is a plain THEOREM computed structurally:
# adding zero is the identity, one cong per column over base's
# Word.add_zero, with the U32 face (U32.add_zero) instantiating it at a
# literal and at an open word.
# ported from bend3: the checker-silent axiom ride becomes a proved
# main, golden {==}
import Base

law Word.add_zero:
  for n: Nat
  for w: Word(n)
  {Word.add(n, w, Word.zero(n)) == w : Word(n)}

def Word.add_zero(n, w):
  match n:
    case 0n:
      match w:
        case WNil{}:
          {==}
    case 1n+p:
      match w:
        case WCon{False{}, t}:
          Equal.cong(Word(p), Word(1n+p), y => WCon{False{}, y}, Word.add(p, t, Word.zero(p)), t, Word.add_zero(p, t))
        case WCon{True{}, t}:
          Equal.cong(Word(p), Word(1n+p), y => WCon{True{}, y}, Word.add(p, t, Word.zero(p)), t, Word.add_zero(p, t))

law U32.add_zero:
  for a: U32
  {U32.add(a, 0) == a : U32}

def U32.add_zero(a):
  match a:
    case U32{x}:
      Equal.cong(Word(32n), U32, w => U32{w}, Word.add(32n, x, Word.zero(32n)), x, Word.add_zero(32n, x))

law measure_hom:
  for w: Word(32n)
  {Word.add(32n, w, Word.zero(32n)) == w : Word(32n)}

def measure_hom(w):
  Word.add_zero(32n, w)

law measure_u32:
  for a: U32
  {(a + 0 : U32) == a : U32}

def measure_u32(a):
  U32.add_zero(a)

law main:
  {(5 + 0 : U32) == 5 : U32}

def main():
  U32.add_zero(5)

#|{==}
