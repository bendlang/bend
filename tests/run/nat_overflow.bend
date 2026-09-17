# Nat overflow is ONE law on every lane: the C helpers post error 7
# (the Nat wall's own text) past NAT_IMM = 2^48-1 and the JS lanes
# throw a line naming the value from nat_chk at add/mul/double/Succ,
# so no lane answers where another fail-stops. 2^24 * 2^24 = 2^48 is
# the first value past the wall.
import Base

law main.out:
  U32

def main.out():
  U32.from_nat(Nat.mul(U32.to_nat(16777216), U32.to_nat(16777216)))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|bend: a Nat past the largest immediate 2^48-1
#|exit 1
