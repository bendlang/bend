# bend3's term_subst fence, scale layer: 32 nested add-closures in one
# body. The subst_nodes/interaction counters are gone (no --stats); the
# composed body itself carries, on base Nat, and answers zero
import Base

law big:
  for x1  : Nat
  for x2  : Nat
  for x3  : Nat
  for x4  : Nat
  for x5  : Nat
  for x6  : Nat
  for x7  : Nat
  for x8  : Nat
  for x9  : Nat
  for x10 : Nat
  for x11 : Nat
  for x12 : Nat
  for x13 : Nat
  for x14 : Nat
  for x15 : Nat
  for x16 : Nat
  for x17 : Nat
  for x18 : Nat
  for x19 : Nat
  for x20 : Nat
  for x21 : Nat
  for x22 : Nat
  for x23 : Nat
  for x24 : Nat
  for x25 : Nat
  for x26 : Nat
  for x27 : Nat
  for x28 : Nat
  for x29 : Nat
  for x30 : Nat
  for x31 : Nat
  for x32 : Nat
  Nat

def big(x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, x16, x17, x18, x19, x20, x21, x22, x23, x24, x25, x26, x27, x28, x29, x30, x31, x32):
  Nat.add(x1, Nat.add(x2, Nat.add(x3, Nat.add(x4, Nat.add(x5, Nat.add(x6, Nat.add(x7, Nat.add(x8, Nat.add(x9, Nat.add(x10, Nat.add(x11, Nat.add(x12, Nat.add(x13, Nat.add(x14, Nat.add(x15, Nat.add(x16, Nat.add(x17, Nat.add(x18, Nat.add(x19, Nat.add(x20, Nat.add(x21, Nat.add(x22, Nat.add(x23, Nat.add(x24, Nat.add(x25, Nat.add(x26, Nat.add(x27, Nat.add(x28, Nat.add(x29, Nat.add(x30, Nat.add(x31, x32)))))))))))))))))))))))))))))))

law main.out:
  Nat

def main.out():
  big(0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n)

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|0n
