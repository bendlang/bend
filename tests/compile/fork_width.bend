# bend3's fork cap ACCEPTED its widest legal 32-sibling parallel let;
# bend's fork-let pairs right-nested with no cap at all (the
# dead-cap law carried, parse_fork_arity_cap_000), so the same 32
# siblings join into one sum on every lane: sum(2i+1, i<32) = 1024
import Base

law leaf:
  for i: U32
  U32

def leaf(i):
  (i * 2 + 1 : U32)

law burst:
  U32

def burst():
  x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 x12 x13 x14 x15 x16 x17 x18 x19 x20 x21 x22 x23 x24 x25 x26 x27 x28 x29 x30 x31 = leaf(0) leaf(1) leaf(2) leaf(3) leaf(4) leaf(5) leaf(6) leaf(7) leaf(8) leaf(9) leaf(10) leaf(11) leaf(12) leaf(13) leaf(14) leaf(15) leaf(16) leaf(17) leaf(18) leaf(19) leaf(20) leaf(21) leaf(22) leaf(23) leaf(24) leaf(25) leaf(26) leaf(27) leaf(28) leaf(29) leaf(30) leaf(31)
  (x0 + x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8 + x9 + x10 + x11 + x12 + x13 + x14 + x15 + x16 + x17 + x18 + x19 + x20 + x21 + x22 + x23 + x24 + x25 + x26 + x27 + x28 + x29 + x30 + x31 : U32)

law main.out:
  Nat

def main.out():
  U32.to_nat(burst())

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|1024n
