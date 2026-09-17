# bend3 whitelisted base's axioms and printed no !! AXIOM line for
# them; bend's exemption IS base.bend -- its unfilled F32 asserts are
# usable silently (the assert-error rule stops at base's edge), and
# the float arithmetic answers on the compiled lanes with no warning
# text anywhere
import Base

law main.out:
  U32

def main.out():
  F32.to_u32((1.5 + 2.5 : F32))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|4
