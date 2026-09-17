# Base Word (the provable machine-word model): width-2 arithmetic wraps
# mod 2^n (3+2 = 1), and the width-generic add_comm theorem instantiates
# at concrete words
# ported from bend3: no from_u32/to_u32 bridge exists (U32 IS Word(32n),
# so there is no hom roster to cross); width-2 words are spelled as WCon
# chains, read back through Word.to_nat, and U32.add_comm is the 32-bit
# face of the same theorem
import Base

law w2_1:
  Word(2n)

def w2_1():
  WCon{True{}, WCon{False{}, WNil{}}}

law w2_2:
  Word(2n)

def w2_2():
  WCon{False{}, WCon{True{}, WNil{}}}

law w2_3:
  Word(2n)

def w2_3():
  WCon{True{}, WCon{True{}, WNil{}}}

law wrap:
  {Word.to_nat(2n, Word.add(2n, w2_3(), w2_2())) == 1n : Nat}

def wrap():
  {==}

law u32_face:
  {U32.add(3, 2) == U32.add(2, 3) : U32}

def u32_face():
  U32.add_comm(3, 2)

law main:
  {Word.add(2n, w2_1(), w2_2()) == Word.add(2n, w2_2(), w2_1()) : Word(2n)}

def main():
  Word.add_comm(2n, w2_1(), w2_2())

#|{==}
