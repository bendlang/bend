# bend3's u32_lit emitted bare C ints and (5 - 7) >> 191 underflowed
# SIGNED in a raw register (interp 2, C 42; the f32 head routed the
# expression through a raw local). bend's shifts take Nat counts and
# words never ride raw C ints -- the pin is cross-lane agreement on
# the wrap-and-shift itself (the f32 head is dropped: interp floats
# are axioms)
import Base

law main.out:
  Nat

def main.out():
  v0 = (41 .&. ((5 - 7) >> 191n) : U32)
  U32.to_nat((v0 + 1 : U32))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|1n
